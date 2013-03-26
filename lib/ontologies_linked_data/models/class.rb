require "set"

module LinkedData
  module Models
    class ClassAttributeNotLoaded < StandardError
    end

    class Class < LinkedData::Models::Base
      model :class,
            :namespace => :owl, :schemaless => :true

      attribute :resource_id #special attribute to name the object manually

      attribute :submission, :collection => lambda { |s| s.resource_id }, :namespace => :metadata

      attribute :prefLabel, :single_value => true , :namespace => :skos # :not_nil => false
      attribute :synonym, :namespace => :skos, :alias => :altLabel
      attribute :definition, :namespace => :skos
      attribute :deprecated, :namespace => :owl, :single_value => true

      attribute :parents, :namespace => :rdfs, :alias => :subClassOf

      #transitive parent
      attribute :ancestors, :use => :parents,
                :query_options => { :rules => :SUBC } #enable subclass of reasoning

      attribute :children, :namespace => :rdfs, :alias => :subClassOf,
                :inverse_of => { :with => :class , :attribute => :parents }

      #transitive children
      attribute :descendents, :use => :children,
                :query_options => { :rules => :SUBC }

      attribute :childrenCount, :aggregate => { :attribute => :children, :with => :count }

      search_options :index_id => lambda { |t| "#{t.resource_id.value}_#{t.submission.ontology.acronym}_#{t.submission.submissionId}" },
                     :document => lambda { |t| t.get_index_doc }

      # Hypermedia settings
      serialize_default :prefLabel, :synonym, :definition, :childrenCount
      serialize_never :submissionAcronym, :submissionId, :submission
      link_to LinkedData::Hypermedia::Link.new("self", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("ontology", lambda { |s| link_path("ontologies/:submission.ontology.acronym", s) },  Goo.namespaces[Goo.namespaces[:default]]+"Ontology"),
              LinkedData::Hypermedia::Link.new("children", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/children", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("parents", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/parents", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("descendents", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/descendents", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("ancestors", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/ancestors", s) }, self.type_uri)

      def get_index_doc
        attrs = {
            :submissionAcronym => self.submission.ontology.acronym,
            :submissionId => self.submission.submissionId
        }

        object_id = self.resource_id.value
        doc = self.attributes.dup
        doc.delete :internals
        doc.delete :uuid
        doc = doc.merge(attrs)
        doc[:resource_id] = object_id

        return doc
      end

      def self.where(*args)
        params = args[0].dup
        missing_labels_generation = params.delete :missing_labels_generation

        inject_subproperty_query_option(params)
        params[:filter]="FILTER(!isBlank(?subject))"
        super(params)
      end

      def self.find(*args)
        args[-1][:query_options] = { rules: :SUBP }
        super(*args)
      end

      def self.link_path(path, cls)
        unless cls.respond_to?(:submission)
          path.sub!(":submission.ontology.acronym", cls.submissionAcronym)
        end
        LinkedData::Hypermedia::expand_link(path, cls)
      end

      def paths_to_root
        return [] if self.parents.nil? or self.parents.length == 0
        paths = [[self]]
        traverse_path_to_root(self.parents, paths)
        return paths
      end

      private

      def append_if_not_there_already(path,r)
        return nil if (path.select { |x| x.resource_id.value == r.resource_id.value }).length > 0
        path << r
      end

      def traverse_path_to_root(parents, paths)
        return if parents.length == 0
        parents.select! { |s| !s.resource_id.bnode?}
        recurse_on_path = []
        if parents.length > 1
          new_paths = paths * parents.length
          paths.delete_if {true}
          new_paths.each do |np|
            paths << np.clone
          end
          paths.each do |p|
            recurse_on_path << false
          end

          parents.each_index do |i|
            path_i = i % paths.length
            path = paths[path_i]
            recurse_on_path[path_i] = recurse_on_path[path_i] || (!append_if_not_there_already(path, parents[i]).nil?)
          end
        else
          paths.each_index do |i|
            recurse_on_path[i] = false
          end
          paths.each_index do |i|
            path = paths[i]
            recurse_on_path[i] = !append_if_not_there_already(path,parents[0]).nil?
          end
        end

        paths.each_index do |i|
          path = paths[i]
          p = path[-1]
          if recurse_on_path[i] and p.parents and p.parents.length > 0
            new_paths = [path]
            traverse_path_to_root p.parents, new_paths
          end
        end
      end

      def self.inject_subproperty_query_option(params)
        #subPropertyOf reasoning by default if loading labels/syns/defs
        if params.include? :load_attrs
          unless params[:load_attrs] == :all
            attrs = params[:load_attrs].instance_of?(Array) ? params[:load_attrs]
                                              : params[:load_attrs].keys
          else
            params[:query_options] = { rules: :SUBP }
            return
          end
          if attrs == :defined ||
            !(attrs & [:prefLabel, :synonym, :definition]).empty?
             params[:query_options] = { rules: :SUBP } if !params.include? :query_options
          end

        end
      end
    end

  end
end
