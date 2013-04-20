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

      attribute :label, :single_value => true , :namespace => :rdfs
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
      embed :children
      serialize_default :prefLabel, :synonym, :definition
      serialize_methods :properties
      serialize_never :submissionAcronym, :submissionId, :submission
      link_to LinkedData::Hypermedia::Link.new("self", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("ontology", lambda { |s| link_path("ontologies/:submission.ontology.acronym", s) },  Goo.namespaces[Goo.namespaces[:default]]+"Ontology"),
              LinkedData::Hypermedia::Link.new("children", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/children", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("parents", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/parents", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("descendents", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/descendents", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("ancestors", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/ancestors", s) }, self.type_uri),
              LinkedData::Hypermedia::Link.new("tree", lambda { |s| link_path("ontologies/:submission.ontology.acronym/classes/:resource_id.value/tree", s) }, self.type_uri)

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
        if cls.attributes[:internals] && cls.attributes[:internals].read_only
          path.sub!(":submission.ontology.acronym", cls.submissionAcronym.first.value)
        end
        LinkedData::Hypermedia::expand_link(path, cls)
      end

      def properties
        cls_all = self.class.find self.resource_id, submission: self.submission, load_attrs: :all
        properties = cls_all.attributes.select {|k,v| k.is_a?(SparqlRd::Resultset::IRI)}
        bad_iri = SparqlRd::Resultset::IRI.new('http://bioportal.bioontology.org/metadata/def/prefLabel')
        properties.delete(bad_iri)
        properties
      end

      def paths_to_root
        return [] if self.parents.nil? or self.parents.length == 0
        paths = [[self]]
        traverse_path_to_root(self.parents, paths, 0)
        paths.each do |p|
          p.reverse!
        end
        return paths
      end

      def tree
        return [] if self.parents.nil? or self.parents.length == 0
        paths = [[self]]
        traverse_path_to_root(self.parents, paths, 0, tree=true)
        path = paths.first
        items_hash = {}
        path.each do |t|
          items_hash[t.resource_id.value] = t
        end

        self.class.where( items: items_hash , load_attrs: { :children => true, :prefLabel => true, :childrenCount => true }, submission: self.submission)
        path.reverse!
        path.last.children.delete_if { |x| true }
        childrens_hash = {}
        path.each do |m|
          m.children.each do |c|
            childrens_hash[c.resource_id.value] = c
          end
        end
        self.class.where( items: childrens_hash , load_attrs: { :prefLabel => true, :childrenCount => true }, submission: self.submission)
        #build the tree
        root_node = path.first
        tree_node = path.first
        path.delete_at(0)
        while tree_node.children.length > 0 and path.length > 0 do
          next_tree_node = nil
          tree_node.children.each_index do |i|
            if tree_node.children[i].resource_id.value == path.first.resource_id.value
              next_tree_node = path.first
              tree_node.children[i] = path.first
            else
              tree_node.children[i].instance_variable_set("@children",[])
            end
          end
          tree_node = next_tree_node
          path.delete_at(0)
        end

        return root_node
      end

      private

      def append_if_not_there_already(path,r)
        return nil if (path.select { |x| x.resource_id.value == r.resource_id.value }).length > 0
        path << r
      end

      def traverse_path_to_root(parents, paths, path_i,tree=false)
        return if (tree and parents.length == 0)
        parents.select! { |s| !s.resource_id.bnode?}
        recurse_on_path = []
        recursions = [path_i]
        recurse_on_path = [false]
        if parents.length > 1 and not tree
          (parents.length-1).times do
            paths << paths[path_i].clone
            recursions << (paths.length - 1)
            recurse_on_path << false
          end

          parents.each_index do |i|
            rec_i = recursions[i]
            recurse_on_path[i] = recurse_on_path[i] || !append_if_not_there_already(paths[rec_i], parents[i]).nil?
          end
        else
          path = paths[path_i]
          recurse_on_path[0] = !append_if_not_there_already(path,parents[0]).nil?
        end

        recursions.each_index do |i|
          rec_i = recursions[i]
          path = paths[rec_i]
          p = path.last
          if (recurse_on_path[i] && p.parents && p.parents.length > 0)
            traverse_path_to_root(p.parents, paths, rec_i, tree=tree)
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
