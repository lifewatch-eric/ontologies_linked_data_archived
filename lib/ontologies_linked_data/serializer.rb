require "xml"
require "date"
require_relative "media_types"
require_relative "serializers/serializers"

module LinkedData
  class Serializer
    def self.build_response(env, options = {})
      status = options[:status] || 200
      headers = options[:headers] || {}
      body = options[:body] || ""
      obj = options[:ld_object] || body

      params = env["rack.request.query_hash"] || Rack::Utils.parse_query(env["QUERY_STRING"])

      best = best_response_type(env, params)

      # Error out if we don't support the foramt
      unless LinkedData::MediaTypes.supported_base_type?(best)
        return response(:status => 415)
      end

      begin
        response(
          :status => status,
          :content_type => "#{LinkedData::MediaTypes.media_type_from_base(best)};charset=utf-8",
          :body => serialize(best, obj, params, Rack::Request.new(env)),
          :headers => headers
        )
      rescue Exception => e
        begin
          if env["rack.test"] || development?
            message = e.message + "\n\n  " + e.backtrace.join("\n  ")
            LOGGER.debug message
            response(:status => 500, :body => message)
          end
        rescue
          # Do nothing
        end
      end
    end

    def self.best_response_type(env, params)
      # Client accept header
      accept = env['rack-accept.request']
      # Out of the media types we offer, which would be best?
      best = LinkedData::MediaTypes.base_type(accept.best_media_type(LinkedData::MediaTypes.all)) unless accept.nil?
      # Try one other method to get the media type
      best ||= LinkedData::MediaTypes.base_type(env["HTTP_ACCEPT"])
      # If user provided a format via query string, override the accept header
      best = params["format"].to_sym if params["format"]
      # Default format if none is provided
      best ||= LinkedData::MediaTypes::DEFAULT
    end

    private

    def self.response(options = {})
      status = options[:status] || 200
      headers = options[:headers] || {}
      body = options[:body] || ""
      content_type = options[:content_type] || "text/plain"
      content_length = options[:content_length] || body.bytesize.to_s
      raise ArgumentError("Body must be a string") unless body.kind_of?(String)
      headers.merge!({"Content-Type" => content_type, "Content-Length" => content_length, "Last-Modified" => last_modified})
      [status, headers, [body]]
    end

    def self.serialize(type, obj, params, request)
      only = params["include"] || []
      only = only.split(",") unless only.kind_of?(Array)
      only, all = [], true if only[0].eql?("all")
      options = {:only => only, :all => all, :params => params, :request => request}
      LinkedData::Serializers.serialize(obj, type, options)
    end

    def self.last_modified
      @last_modified ||= DateTime.now
      now = DateTime.now
      if now.to_time - @last_modified.to_time > 300
        @last_modified = now
      end
      @last_modified.iso8601
    end

  end
end