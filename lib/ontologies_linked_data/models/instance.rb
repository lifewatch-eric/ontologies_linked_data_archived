
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

      def add_property_value(p,o)
        ps = p.to_s
        if not @properties.include?(ps)
          @properties[ps] = []
        end
        @properties[ps] << o
      end

      def self.type_uri
        LinkedData.settings.id_url_prefix+"metadata/Instance"
      end
    end
  end
  module InstanceLoader
    def self.get_instances_by_class(submission_id,class_id)
      query = <<-eos
PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT ?s ?label WHERE
  {
    GRAPH <#{submission_id.to_s}> {
        ?s a owl:NamedIndividual .
        ?s a <#{class_id.to_s}> .
    }
  }
eos
      epr = Goo.sparql_query_client(:main)
      graphs = [submission_id]
      resultset = epr.query(query, graphs: graphs)
      instances = []
      resultset.each do |r|
        inst = LinkedData::Models::Instance.new(r[:s],nil,{})
        instances << inst
      end
      include_instance_properties(submission_id,instances)
      return instances
    end

    def self.get_instances_by_ontology(submission_id,page_no,size)
      offset = (page_no-1) * size
      limit = size
      query = <<-eos
PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT ?s ?label WHERE
  {
    GRAPH <#{submission_id.to_s}> {
        ?s a owl:NamedIndividual .
    }
    OFFSET #{offset} LIMIT #{limit}
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
      include_instance_properties(submission_id,instances)
      page = Goo::Base::Page.new(page_no,size,nil,instances)
      return page
    end

    def self.include_instance_properties(submission_id,instances)
      index = Hash.new
      instances.each do |inst|
        index[inst.id.to_s] = inst
      end
      uris = index.keys.map { |x| x.to_s }
      uri_filter = uris.map { |x| "?s = <#{x}>"}.join(" || ")

      query = <<-eos
PREFIX owl: <http://www.w3.org/2002/07/owl#>
SELECT ?s ?p ?o WHERE
  {
    GRAPH <#{submission_id.to_s}> {
        ?s ?p ?o .
    }
    FILTER( #{uri_filter} )
  }
eos
      epr = Goo.sparql_query_client(:main)
      graphs = [submission_id]
      resultset = epr.query(query, graphs: graphs)
      resultset.each do |sol|
        s = sol[:s]
        p = sol[:p]
        o = sol[:o]
        if not p.to_s["label"].nil?
          index[s.to_s].label = o.to_s
        else
          index[s.to_s].add_property_value(p,o)
        end
      end

    end
  end
end
