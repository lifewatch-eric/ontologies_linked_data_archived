module LinkedData
  module Models
    class Class

      attr_reader :resource_id
      attr_reader :submission

      def initialize(resource_id, submission, plabel = nil, synonyms = nil)
        @resource_id = resource_id

        @attributes = {}

        if !plabel.nil?
          set_prefLabel plabel
        end
        @attributes[:synonyms] = synonyms

        #backreference to the submission that "owns" the term
        @submission = submission
      end

      private

      def set_prefLabel(label_input)
        label = nil
        if label_input.instance_of? Array
          if label_input.length > 1
            raise ArgumentError, "Class model only allows one label. TODO: internationalization"
          end
          if label_input.length == 1
            label = label_input[0]
          end
        else
          label = label_input
        end
        if label.instance_of? SparqlRd::Resultset::Literal
          @attributes[:prefLabel] = label
        else
          raise ArgumentError, "Unknown type of prefLabel #{label.class.name}"
        end
      end

      public

      def prefLabel
        return @attributes[:prefLabel]
      end

      def synonymLabel
        return [] if @attributes[:synonyms].nil?
        @attributes[:synonyms].select!{ |sy| sy != nil }
        return @attributes[:synonyms]
      end

      def loaded_parents?
        return !@attributes[:parents].nil?
      end


      def loaded_children?
        return !@attributes[:children].nil?
      end

      def self.find(*args)
        raise ArgumentError,
          "Find is not supported in the Class model. Use .where (:submission => s, :resource_id => id)"
        #TODO eventually we can bypass this exception and call .where directly.
      end

      def load_parents
        parents = load_relatives
        @attributes[:parents] = parents
        return parents
      end

      def load_children
        children = load_relatives(children=true)
        @attributes[:children]  = children
        return children
      end

      def load_relatives(children=false)
        #by default loads parents
        hierarchyProperty = @submission.hierarchyProperty ||
                                LinkedData::Utils::Namespaces.default_hieararchy_property
        graph = submission.resource_id
        if children
          relative_pattern = " ?relativeId <#{hierarchyProperty.value}> <#{self.resource_id.value}> . "
        else
          relative_pattern = " <#{self.resource_id.value}> <#{hierarchyProperty.value}> ?relativeId . "
        end
        query = <<eos
SELECT DISTINCT ?relativeId WHERE {
  GRAPH <#{graph.value}> {
    #{relative_pattern}
    FILTER (!isBLANK(?parentId))
} } ORDER BY ?id
eos
        rs = Goo.store.query(query)
        relatives = []
        rs.each_solution do |sol|
          relatives << LinkedData::Models::Class.new(sol.get(:relativeId), self.submission)
        end
        return relatives
      end

      def parents
        raise ArgumentError, "Parents are not loaded. Call .load_parents" \
          unless self.loaded_parents?
        return @attributes[:parents]
      end

      def children
        raise ArgumentError, "Children are not loaded. Call .load_children" \
          unless self.loaded_children?
        return @attributes[:children]
      end

      def self.where(*args)
        params = args[0]
        submission = params[:submission]
        if submission.nil?
          raise ArgumentError, "Submission needs to be provided to retrieve terms"
        end

        graph = submission.resource_id
        submission.load if (!submission.nil? and !submission.loaded?)
        classType =  submission.classType || LinkedData::Utils::Namespaces.default_type_for_classes
        load_labels = true

        one_class_filter = ""
        if params.include? :resource_id
          resource_id = params[:resource_id]
          raise ArgumentError, "Resource ID Class.where needs to be a RDF::IRI" \
            unless resource_id.kind_of? RDF::IRI
          one_class_filter = "FILTER (?id = <#{resource_id.value}>)"
        end

        root_class_filter = ""
        if params.include? :root and params[:root]
          #TODO: UMLS ontologies behave differently
          hierarchyProperty = submission.hierarchyProperty ||
                                  LinkedData::Utils::Namespaces.default_hieararchy_property
          root_class_filter = <<eos
OPTIONAL { ?id <#{hierarchyProperty.value}> ?superId .}
FILTER(!bound(?superId))
eos
          load_labels = false
        end

        labels_block = ""
        if load_labels
          syn_predicate = LinkedData::Utils::Namespaces.default_altLabel_iri
          if params.include? :missing_labels_generation
            syn_predicate = LinkedData::Utils::Namespaces.rdfs_label_iri
          end
          labels_block = <<eos
OPTIONAL { ?id <#{LinkedData::Utils::Namespaces.default_pref_label.value}> ?prefLabel . }
OPTIONAL { ?id <#{syn_predicate.value}> ?synonymLabel . }
eos
        end

        query = <<eos
SELECT DISTINCT * WHERE {
  GRAPH <#{graph.value}> {
    ?id a <#{classType.value}> .
    #{labels_block}
    #{one_class_filter}
    #{root_class_filter}
    FILTER(!isBLANK(?id))
} } ORDER BY ?id
eos
        rs = Goo.store.query(query)
        classes = []
        rs.each_solution do |sol|
          if load_labels and ((classes.length > 0) and (classes[-1].resource_id.value == sol.get(:id).value))
            classes[-1].synonymLabel << sol.get(:synonymLabel)
          else
            if load_labels
              classes << Class.new(sol.get(:id), submission, sol.get(:prefLabel), [sol.get(:synonymLabel)])
            else
              classes << Class.new(sol.get(:id), submission)
            end
          end
        end
        return classes
      end

    end
  end
end
