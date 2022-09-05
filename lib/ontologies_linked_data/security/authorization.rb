require 'set'
require 'oauth2'
module LinkedData
  module Security
    class Authorization
      APIKEYS_FOR_AUTHORIZATION = {}

      def initialize(app = nil)
        @app = app
        @semaphore = Mutex.new
        if LinkedData.settings.oauth2_enabled
          begin
            @oath2Client = OAuth2::Client.new(LinkedData.settings.oauth2_client_id, LinkedData.settings.oauth2_client_secret, {site: LinkedData.settings.oauth2_site, token_url: "oauth2/token", ssl: LinkedData.settings.oauth2_ssl})
            @oath2ClientToken = @oath2Client.client_credentials.get_token("scope" => LinkedData.settings.oauth2_token_introspection_scope)
          rescue OAuth2::Error => e
            LOGGER.info("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
            raise e
          end
        end
      end

      def oath2_client_token()
        token = nil
        @semaphore.synchronize do
          token = @oath2ClientToken
        end

        if token.expired?
          token = @oath2Client.client_credentials.get_token("scope" => LinkedData.settings.oauth2_token_introspection_scope)

          @semaphore.synchronize do
            @oath2ClientToken = token
          end

        end

        token
      end

      ROUTES_THAT_BYPASS_SECURITY = Set.new([
        "/",
        "/documentation",
        "/jsonview/jsonview.css",
        "/jsonview/jsonview.js"
      ])

      def call(env)
        req = Rack::Request.new(env)
        params = req.params

        accessToken = find_access_token(env, params)
        apikey = accessToken ? nil : find_apikey(env, params)

        if apikey
          if !authorized?(apikey, env)
            status = 401
            response = {
              status: status,
              error: "You must provide a valid API Key. " + \
              "Your API Key can be obtained by logging in at #{LinkedData.settings.ui_host}/account"
            }
          end
        elsif accessToken
          begin
          introspectionResponse = oath2_client_token.post("/oauth2/introspect", {body: {"token" => accessToken}})
          rescue OAuth2::Error => e
            LOGGER.debug("#{e.class}: #{e.message}\n#{e.backtrace.join("\n\t")}")
            raise e
          end

          unless introspectionResponse.parsed.active
            status = 401
            response = {
              status: status,
              error: "The provided access token is not valid."
            }
          end

          if status != 401
            username = introspectionResponse.parsed.username

            # the token returns a qualified username with source (e.g. LIFEWATCH.EU) and domain (e.g. @carbon)
            if status != 401 && LinkedData.settings.oauth2_token_username_extractor
              if usernameMatch = LinkedData.settings.oauth2_token_username_extractor.match(username)
                username = usernameMatch["username"]
              else
                status = 401
                response = {
                  status: status,
                  error: "Username does not match the extraction pattern"
                }
              end
            end

            if status != 401
              scope = introspectionResponse.parsed.scope

              scopes = []
              if scope
                scopes = scope.split()
              end

              unless !LinkedData.settings.oauth2_token_scope_matcher || scopes.any?(LinkedData.settings.oauth2_token_scope_matcher)
                status = 401
                response = {
                  status: status,
                  error: "The provided access token doesn't meet the required scope"
                }
              end

              user = LinkedData::Models::User.where(username: username).include(LinkedData::Models::User.attributes(:all)).first
              if user
                store_user(user, env)
              else
                status = 401
                response = {
                  status: status,
                  error: "The user who granted the access token is not recognized"
                }
              end
            end
          else
            status = 401
            response = {
              status: status,
              error: "You must provide an API Key either using the query-string parameter `apikey` or the `Authorization` header: `Authorization: apikey token=my_apikey`. " + \
              "Your API Key can be obtained by logging in at #{LinkedData.settings.ui_host}/account" + \
              "Alternatively, you must supply an OAuth2 access token in the `Authorization` header: `Authorization: Bearer oauth2-access-token`."
            }
          end
        end
        if status == 401 && !bypass?(env)
          LinkedData::Serializer.build_response(env, status: status, body: response)
        else
          status, headers, response = @app.call(env)
          apikey_cookie(env, headers, apikey, params)
          [status, headers, response]
        end
      end

      # Skip auth unless security is enabled or for routes we know should be allowed
      def bypass?(env)
        return !LinkedData.settings.enable_security \
          || ROUTES_THAT_BYPASS_SECURITY.include?(env["REQUEST_PATH"]) \
          || env["HTTP_REFERER"] && env["HTTP_REFERER"].start_with?(LinkedData.settings.rest_url_prefix)
      end

      ##
      # Inject a cookie with the API Key if it is present and we're in HTML content type
      def apikey_cookie(env, headers, apikey, params)
        # If we're using HTML, inject the apikey in a cookie (ignores bad accept headers)
        begin
          best = LinkedData::Serializer.best_response_type(env, params)
        rescue LinkedData::Serializer::AcceptHeaderError; end
        if best == LinkedData::MediaTypes::HTML
          Rack::Utils.set_cookie_header!(headers, "ncbo_apikey", {:value => apikey, :path => "/", :expires => Time.now+90*24*60*60})
        end
      end

      def find_access_token(env, params)
        access_token = nil
        header_auth = env["HTTP_AUTHORIZATION"] || env["Authorization"]
        if header_auth && header_auth.downcase().start_with?("bearer ")
          access_token = header_auth.split()[1]
        end
        access_token
      end

      def find_apikey(env, params)
        apikey = nil
        header_auth = env["HTTP_AUTHORIZATION"] || env["Authorization"]
        if params["apikey"] && params["userapikey"]
          apikey_authed = authorized?(params["apikey"], env)
          return unless apikey_authed
          apikey = params["userapikey"]
        elsif params["apikey"]
          apikey = params["apikey"]
        elsif apikey.nil? && header_auth
          token = Rack::Utils.parse_query(header_auth.split(" ")[1])
          # Strip spaces from start and end of string
          apikey = token["token"].gsub(/\"/, "")
          # If the user apikey is passed, use that instead
          if token["userapikey"] && !token["userapikey"].empty?
            apikey_authed = authorized?(apikey, env)
            return unless apikey_authed
            apikey = token["userapikey"].gsub(/\"/, "")
          end
        elsif apikey.nil? && env["HTTP_COOKIE"] && env["HTTP_COOKIE"].include?("ncbo_apikey")
          cookie = Rack::Utils.parse_query(env["HTTP_COOKIE"])
          apikey = cookie["ncbo_apikey"] if cookie["ncbo_apikey"]
        end
        apikey
      end

      def authorized?(apikey, env)
        return false if apikey.nil?
        if APIKEYS_FOR_AUTHORIZATION.key?(apikey)
          store_user(APIKEYS_FOR_AUTHORIZATION[apikey], env)
        else
          users = LinkedData::Models::User.where(apikey: apikey).include(LinkedData::Models::User.attributes(:all)).to_a
          return false if users.empty?
          # This will kind-of break if multiple apikeys exist
          # Though it is also kind-of ok since we just want to know if a user with corresponding key exists
          user = users.first
          store_user(user, env)
        end
        return true
      end

      def store_user(user, env)
        Thread.current[:remote_user] = user
        env.update("REMOTE_USER" => user)
      end

    end
  end
end
