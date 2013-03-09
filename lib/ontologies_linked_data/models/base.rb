require 'active_support/core_ext/string'

module LinkedData
  module Models
    class Base < Goo::Base::Resource
      include LinkedData::Hypermedia::Resource

      def resource_id
        id = super
        hack_resource_id(id)
      end

      def resource_id=(id)
        super(hack_resource_id(id))
      end

      private

      def hack_resource_id(id)
        if id.value.match("http://data.bioontology.org/metadata")
          path = id.value.sub("http://data.bioontology.org/metadata", "")
          path = path.split("/")
          path[1] = path[1].pluralize
          path[0] = $REST_URL_PREFIX
          id = RDF::IRI.new(path.join("/"))
        end
        id
      end
    end
  end
end