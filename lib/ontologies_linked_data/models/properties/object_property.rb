require 'ontologies_linked_data/models/properties/ontology_property'

module LinkedData
  module Models

    class ObjectProperty < LinkedData::Models::OntologyProperty
      model :object_property, name_with: :id, collection: :submission,
            namespace: :owl, :schemaless => :true,
            rdf_type: lambda { |*x| RDF::OWL[:ObjectProperty] }

      PROPERTY_TYPE = "OBJECT"

      attribute :submission, :collection => lambda { |s| s.resource_id }, :namespace => :metadata
      attribute :label, namespace: :rdfs, enforce: [:list]
      attribute :definition, namespace: :skos, enforce: [:list], alias: true
      attribute :parents, namespace: :rdfs, enforce: [:list, :object_property], property: :subPropertyOf
      attribute :children, namespace: :rdfs, inverse: { on: :object_property, :attribute => :parents }
      # attribute :domain
      # attribute :range

      search_options :index_id => lambda { |t| "#{t.id.to_s}_#{t.submission.ontology.acronym}_#{t.submission.submissionId}" },
                     :document => lambda { |t| t.get_index_doc }

      serialize_default :label, :labelGenerated, :definition, :matchType, :ontologyType, :propertyType, :parents, :children, :hasChildren # some of these attributes are used in Search (not shown out of context)


      # serialize_methods :hasChildren



      # this command allows the parents and children to be serialized in the output
      embed :children



      link_to LinkedData::Hypermedia::Link.new("self", lambda {|m| "#{self.ontology_link(m)}/properties/#{CGI.escape(m.id.to_s)}"}, self.type_uri),
              LinkedData::Hypermedia::Link.new("ontology", lambda {|m| self.ontology_link(m)}, Goo.vocabulary["Ontology"]),
              LinkedData::Hypermedia::Link.new("submission", lambda {|m| "#{self.ontology_link(m)}/submissions/#{m.submission.id.to_s.split("/")[-1]}"}, Goo.vocabulary["OntologySubmission"])

















      def tree
        self.bring(parents: [:label]) if self.bring?(:parents)
        threshhold = 99


        # return self if self.parents.nil? or self.parents.length == 0


        paths = [[self]]

        traverse_path_to_root(self.parents.dup, paths, 0, tree=true, top_property="#topObjectProperty")

        items_hash = {}
        path = paths[0]

        path.each do |t|
          items_hash[t.id.to_s] = t
        end

        self.class.partially_load_children(items_hash.values, threshhold, self.submission)

        path.reverse!
        path.last.instance_variable_set("@children",[])
        childrens_hash = {}

        path.each do |m|
          next if m.id.to_s["#topObjectProperty"]

          m.children.each do |c|
            childrens_hash[c.id.to_s] = c
          end
        end

        self.class.partially_load_children(childrens_hash.values, threshhold, self.submission)

        #build the tree
        root_node = path.first
        tree_node = path.first
        path.delete_at(0)

        while tree_node && !tree_node.id.to_s["#topObjectProperty"] && tree_node.children.length > 0 and path.length > 0 do
          next_tree_node = nil
          tree_node.load_has_children

          tree_node.children.each_index do |i|
            if tree_node.children[i].id.to_s == path.first.id.to_s
              next_tree_node = path.first
              children = tree_node.children.dup
              children[i] = path.first
              tree_node.instance_variable_set("@children", children)

              children.each do |c|
                c.load_has_children
              end
            else
              tree_node.children[i].instance_variable_set("@children", [])
            end
          end

          if path.length > 0 && next_tree_node.nil?
            tree_node.children << path.shift
          end

          tree_node = next_tree_node
          path.delete_at(0)
        end





        root_node
      end






      # def self.tree_view_property(*args)
      #   submission = args.first
      #   unless submission.loaded_attributes.include?(:hasOntologyLanguage)
      #     submission.bring(:hasOntologyLanguage)
      #   end
      #   if submission.hasOntologyLanguage
      #
      #
      #     binding.pry
      #
      #
      #     return submission.hasOntologyLanguage.tree_property
      #   end
      #   return RDF::RDFS[:subPropertyOf]
      # end







    end

  end
end
