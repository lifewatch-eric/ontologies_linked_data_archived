require 'set'

module LinkedData
  module Security
    class Authorization
      APIKEYS_FOR_AUTHORIZATION = {}

      def initialize(app = nil)
        @app = app
      end

      ROUTES_THAT_BYPASS_SECURITY = Set.new([
        "/",
        "/documentation",
        "/jsonview/jsonview.css",
        "/jsonview/jsonview.js"
      ])

      def call(env)
        # Skip auth unless security is enabled or for routes we know should be allowed
        return @app.call(env) unless LinkedData.settings.enable_security
        return @app.call(env) if ROUTES_THAT_BYPASS_SECURITY.include?(env["REQUEST_PATH"])
        return @app.call(env) if env["HTTP_REFERER"] && env["HTTP_REFERER"].start_with?(LinkedData.settings.rest_url_prefix)

        params = env["rack.request.query_hash"] || Rack::Utils.parse_query(env["QUERY_STRING"])

        apikey = find_apikey(env, params)

        unless apikey
          status = 403
          response = {
            status: status,
            error: "You must provide an API Key either using the query-string parameter `apikey` or the `Authorization` header: `Authorization: apikey token=my_apikey`. " + \
              "An API Key can be obtained by logging in at http://bioportal.bioontology.org/account"
          }
        end

        if status != 403 && !authorized?(apikey, env)
          status = 403
          response = {
            status: status,
            error: "You must provide a valid API Key. " + \
              "An API Key can be obtained by logging in at http://bioportal.bioontology.org/account"
          }
        end

        if status == 403
          LinkedData::Serializer.build_response(env, status: status, body: response)
        else
          status, headers, response = @app.call(env)
          apikey_cookie(env, headers, apikey, params)
          [status, headers, response]
        end
      end

      ##
      # Inject a cookie with the API Key if it is present and we're in HTML content type
      def apikey_cookie(env, headers, apikey, params)
        # If we're using HTML, inject the apikey in a cookie
        best = LinkedData::Serializer.best_response_type(env, params)
        if best == LinkedData::MediaTypes::HTML
          Rack::Utils.set_cookie_header!(headers, "ncbo_apikey", {:value => apikey, :path => "/", :expires => Time.now+14*24*60*60})
        end
      end

      def find_apikey(env, params)
        apikey = nil
        header_auth = env["HTTP_AUTHORIZATION"] || env["Authorization"]
        if params["apikey"]
          apikey = params["apikey"]
        elsif apikey.nil? && header_auth
          token = Rack::Utils.parse_query(header_auth.split(" ")[1])
          # Strip spaces from start and end of string
          apikey = token["token"].sub(/^\"(.*)\"$/) { $1 }
        elsif apikey.nil? && env["HTTP_COOKIE"] && env["HTTP_COOKIE"].include?("ncbo_apikey")
          cookie = Rack::Utils.parse_query(env["HTTP_COOKIE"])
          apikey = cookie["ncbo_apikey"] if cookie["ncbo_apikey"]
        end
        apikey
      end

      def authorized?(apikey, env)
        return false if apikey.nil?
        if APIKEYS_FOR_AUTHORIZATION.key?(apikey)
          env["REMOTE_USER"] = APIKEYS_FOR_AUTHORIZATION[apikey]
        else
          users = LinkedData::Models::User.where(apikey: apikey).include(LinkedData::Models::User.attributes(:all)).to_a
          return false if users.empty?
          # This will kind-of break if multiple apikeys exist
          # Though it is also kind-of ok since we just want to know if a user with corresponding key exists
          user = users.first
          env["REMOTE_USER"] = user
        end
        return true
      end

    end
  end
end