module LinkedData
  module Serializers
    class HTML
      def self.serialize(obj, options)
        @app_reference ||= ObjectSpace.each_object(Sinatra::Application).first
        object_for_render = LinkedData::Serializers::JSON.serialize(obj, options)
        @app_reference.haml :json_as_html, locals: { object_for_render: object_for_render }
      end
    end
  end
end

