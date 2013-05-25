require "set"
#require 'redis'

module LinkedData
  module Models
    class ClassAttributeNotLoaded < StandardError
    end

    class Class < LinkedData::Models::Base
      model :class, name_with: :id, collection: :submission,
            namespace: :owl, :schemaless => :true

      attribute :submission, :collection => lambda { |s| s.resource_id }, :namespace => :metadata

      attribute :label, namespace: :rdfs,enforce: [:list], alias: true
      attribute :prefLabel, namespace: :skos, enforce: [:existence], alias: true
      attribute :synonym, namespace: :skos, enforce: [:list], property: :altLabel, alias: true
      attribute :definition, namespace: :skos, enforce: [:list], alias: true
      attribute :deprecated, namespace: :owl

      attribute :notation, namespace: :skos

      attribute :parents, namespace: :rdfs, property: :subClassOf, enforce: [:list, :class]

      #transitive parent
      attribute :ancestors, namespace: :rdfs, property: :subClassOf, enforce: [:list, :class],
                  transitive: true

      attribute :children, namespace: :rdfs, property: :subClassOf, 
                  inverse: { on: :class , :attribute => :parents }

      #transitive children
      attribute :descendants, namespace: :rdfs, property: :subClassOf, 
                    inverse: { on: :class , attribute: :parents },
                    transitive: true

      search_options :index_id => lambda { |t| "#{t.id.to_s}_#{t.submission.ontology.acronym}_#{t.submission.submissionId}" },
                     :document => lambda { |t| t.get_index_doc }

      # Hypermedia settings
      embed :children, :ancestors, :descendants, :parents
      serialize_default :prefLabel, :synonym, :definition
      serialize_methods :properties
      serialize_never :submissionAcronym, :submissionId, :submission
      link_to LinkedData::Hypermedia::Link.new("self", lambda {|s| "ontologies/#{s.ontology.acronym}/classes/#{s.id}"}, self.uri_type),
              LinkedData::Hypermedia::Link.new("ontology", lambda {|s| "ontologies/#{s.ontology.acronym}"},  Goo.vocabulary["Ontology"]),
              LinkedData::Hypermedia::Link.new("children", lambda {|s| "ontologies/#{s.ontology.acronym}/classes/#{s.id}/children"}, self.uri_type),
              LinkedData::Hypermedia::Link.new("parents", lambda {|s| "ontologies/#{s.ontology.acronym}/classes/#{s.id}/parents"}, self.uri_type),
              LinkedData::Hypermedia::Link.new("descendants", lambda {|s| "ontologies/#{s.ontology.acronym}/classes/#{s.id}/descendants"}, self.uri_type),
              LinkedData::Hypermedia::Link.new("ancestors", lambda {|s| "ontologies/#{s.ontology.acronym}/classes/#{s.id}/ancestors"}, self.uri_type),
              LinkedData::Hypermedia::Link.new("tree", lambda {|s| "ontologies/#{s.ontology.acronym}/classes/#{s.id}/tree"}, self.uri_type)

      def get_index_doc
        doc = {
            :resource_id => self.id.to_s,
            :ontologyId => self.submission.id.to_s,
            :submissionAcronym => self.submission.ontology.acronym,
            :submissionId => self.submission.submissionId,
        }
        all_attrs = self.to_hash
        std = [:id, :prefLabel, :notation, :synonym, :definition]
        std.each do |att|
          doc[att] = all_attrs[att].to_s
          all_attrs.delete att
        end
        all_attrs.delete :submission
        props = []

        #for redundancy with prefLabel
        all_attrs.delete :label

        all_attrs.each do |attr_key, attr_val|
          if (!doc.include?(attr_key))
            if (attr_val.is_a?(Array))
              attr_val = attr_val.uniq
              attr_val.map { |val| props << (val.kind_of?(Goo::Base::Resource) ? val.id.to_s : val.to_s.strip) } rescue binding.pry
            else
              props << attr_val.to_s.strip
            end
          end
        end
        props.uniq!
        doc[:property] = props
        return doc
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
          items_hash[t.id.to_s] = t
        end

        self.class.where( items: items_hash , load_attrs: { :children => true, :prefLabel => true, :childrenCount => true }, submission: self.submission)
        path.reverse!
        path.last.children.delete_if { |x| true }
        childrens_hash = {}
        path.each do |m|
          m.children.each do |c|
            childrens_hash[c.id.to_s] = c
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
            if tree_node.children[i].id.to_s == path.first.id.to_s
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

#      def self.page(*args)
      #
      #      consider this
      #      params[:filter]="FILTER(!isBlank(?subject))"
      #
#        parsing = args.last.delete(:parsing)
#        if parsing
#          return super(args.last)
#        end
#        redis_cl = LinkedData.redis_client
#        if !redis_cl.exists(args.last[:submission].cache_pagination_key)
#          return super(args.last)
#        end
#        page_n = args.last.delete(:page)
#        size = args.last.delete(:size)
#        count = redis_cl.llen(args.last[:submission].cache_pagination_key)
#        page_count = ((count+0.0)/size).ceil
#        offset = (page_n-1) * size
#        ids = redis_cl.lrange(args.last[:submission].cache_pagination_key, offset, offset + size)
#        items_hash = {}
#        ids.each do |id|
#          resource_id = SparqlRd::Resultset::IRI.new id
#          item = self.new
#          item.internals.lazy_loaded
#          item.resource_id = resource_id
#          items_hash[resource_id.value] = item
#          collection = args.last[:submission]
#          item.internals.collection = collection
#          item.internals.graph_id = collection
#          item.internals.lazy_loaded
#        end
#        items = nil
#        if items_hash.length > 0 and count > 0
#          items = self.where(args[-1].merge({ items: items_hash }))
#        else
#          items = []
#        end
#        next_page = items.size > size
#        items = items[0..-2] if items.length > size
#        return Goo::Base::Page.new(page_n,next_page,page_count,items)
#      end

      private

      def append_if_not_there_already(path,r)
        return nil if (path.select { |x| x.id.to_s == r.id.to_s }).length > 0
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
