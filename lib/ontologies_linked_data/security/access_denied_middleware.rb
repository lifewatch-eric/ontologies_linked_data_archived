module LinkedData
  module Security
    class AccessDenied
      def initialize(app = nil)
        @app = app
      end

      def call(env)
        begin
          @app.call(env)
        rescue LinkedData::Security::WriteAccessDeniedError
          Rack::Response.new("Access denied for this resource", 403, {}).finish
        end
      end
    end
  end
end