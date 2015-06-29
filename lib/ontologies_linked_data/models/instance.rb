
module LinkedData
  module Models
    class Instance
      include LinkedData::Hypermedia::Resource

      serialize_default :id, :label, :properties

      def initialize(id,label,properties)
        @id = id
        if label.nil?
          sep = "/"
          if not id.to_s["#"].nil?
            sep = "#"
          end
          label = id.to_s.split(sep).last
        end
        @label = label
        @properties = properties
      end
      def id
        return @id
      end
      def label
        return @label
      end
      def properties
        return @properties
      end
      def self.type_uri
        LinkedData.settings.id_url_prefix+"metadata/Instance"
      end
    end
  end
  module InstanceLoader
    def self.get_instances(submission_id,class_id)
      query = <<-eos
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?s ?label WHERE
  {
    GRAPH <#{submission_id.to_s}> {
        ?s a owl:NamedIndividual .
        ?s a <#{class_id.to_s}> .
        OPTIONAL {
          ?s rdfs:label ?label .
        }
    }
  }
eos
      epr = Goo.sparql_query_client(:main)
      graphs = [submission_id]
      resultset = epr.query(query, graphs: graphs)
      instances = []
      resultset.each do |r|
        inst = LinkedData::Models::Instance.new(r[:s],r[:label],{})
        instances << inst
      end
      return instances
    end
  end
end
