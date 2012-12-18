module LinkedData
  module Models
    class Class

      @@DEFAULT_PREF_LABEL = RDF::IRI.new("http://www.w3.org/2004/02/skos/core#prefLabel")
      @@DEFAULT_TYPE = RDF::IRI.new("http://www.w3.org/2002/07/owl#Class")

      attr_accessor :id
      attr_accessor :prefLabel

      def initialize(id, prefLabel = nil)
        @id = id
        @prefLabel = prefLabel
      end

      def self.where(*args)
        if args.length == 1 and args[0].include? :graph and args[0][:graph].kind_of? RDF::IRI
          params = args[0]
          graph = params[:graph]
          prefLabelProperty =  params[:prefLabelProperty] || @@DEFAULT_PREF_LABEL
          classType =  params[:classType] || @@DEFAULT_TYPE

          query = <<eos
SELECT DISTINCT ?id ?label WHERE {
  GRAPH <#{graph.value}> {
    ?id a <#{classType.value}> .
    OPTIONAL { ?id <#{prefLabelProperty.value}> ?label . }
} }
eos
          rs = Goo.store.query(query)
          classes = []
          rs.each_solution do |sol|
            classes << Class.new(sol.get(:id), sol.get(:label))
          end
          return classes
        else
          raise ArgumentError, "Current Class implementation search capabilities are minimal" 
        end
      end
    end
  end
end
