
module LinkedData
  module Models

    class OntologyProperty < LinkedData::Models::Base


      def hasChildren
        if instance_variable_get("@intlHasChildren").nil?
          raise ArgumentError, "HasChildren not loaded for #{self.id.to_ntriples}"
        end

        @intlHasChildren
      end

      def tree
        self.bring(parents: [:label]) if self.bring?(:parents)
        threshold = 99
        return self if self.parents.nil? or self.parents.length == 0
        paths = [[self]]

        traverse_path_to_root(self.parents.dup, paths, 0, tree=true, top_property=self.class::TOP_PROPERTY)

        items_hash = {}
        path = paths[0]
        path.each { |t| items_hash[t.id.to_s] = t }

        self.class.partially_load_children(items_hash.values, threshold, self.submission)

        path.reverse!
        path.last.instance_variable_set("@children", [])
        childrens_hash = {}

        path.delete_if do |m|
          next if self.class::TOP_PROPERTY && m.id.to_s[self.class::TOP_PROPERTY]

          # handle https://github.com/ncbo/ontologies_linked_data/issues/71
          begin
            m.children.each { |c| childrens_hash[c.id.to_s] = c }
            false
          rescue Goo::Base::AttributeNotLoaded => e
            true
          end
        end

        self.class.partially_load_children(childrens_hash.values, threshold, self.submission)

        #build the tree
        root_node = path.first
        tree_node = path.first
        path.delete_at(0)

        while tree_node && (self.class::TOP_PROPERTY.nil? || !tree_node.id.to_s[self.class::TOP_PROPERTY]) && tree_node.children.length > 0 and path.length > 0 do
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

      def load_has_children
        unless instance_variable_get("@intlHasChildren").nil?
          return
        end

        graphs = [self.submission.id.to_s]
        query = has_children_query(self.id.to_s, graphs.first)
        has_c = false

        Goo.sparql_query_client.query(query, query_options: {rules: :NONE }, graphs: graphs).each do |sol|
          has_c = true
        end

        @intlHasChildren = has_c
      end

      def has_children_query(class_id, submission_id)
        property_tree = RDF::RDFS[:subPropertyOf]

        pattern = "?c <#{property_tree.to_s}> <#{class_id.to_s}> . "
        query = <<eos
SELECT ?c WHERE {
GRAPH <#{submission_id}> {
  #{pattern}
}
}
LIMIT 1
eos
        query
      end

      def get_index_doc
        self.bring(:label) if self.bring?(:label)
        self.bring(:submission) if self.bring?(:submission)
        self.submission.bring(:submissionId) if self.submission.bring?(:submissionId)
        self.submission.bring(:ontology) if self.submission.bring?(:ontology)
        self.submission.ontology.bring(:acronym) if self.submission.ontology.bring?(:acronym)
        self.submission.ontology.bring(:ontologyType) if self.submission.ontology.bring?(:ontologyType)

        doc = {
            :resource_id => self.id.to_s,
            :ontologyId => self.submission.id.to_s,
            :submissionAcronym => self.submission.ontology.acronym,
            :submissionId => self.submission.submissionId,
            :ontologyType => self.submission.ontology.ontologyType.get_code_from_id,
            :propertyType => self.class::PROPERTY_TYPE,
            :labelGenerated => LinkedData::Utils::Triples.generated_label(self.id, self.label)
        }

        all_attrs = self.to_hash
        std = [:id, :label, :definition, :parents]

        std.each do |att|
          cur_val = all_attrs[att]
          # don't store empty values
          next if cur_val.nil? || (cur_val.respond_to?('empty?') && cur_val.empty?)

          if cur_val.is_a?(Array)
            doc[att] = []
            cur_val = cur_val.uniq
            cur_val.map { |val| doc[att] << (val.kind_of?(Goo::Base::Resource) ? val.id.to_s : val.to_s.strip) }
          else
            doc[att] = cur_val.to_s.strip
          end
        end

        doc
      end

      def append_if_not_there_already(path, r, top_property=nil)
        return nil if top_property && r.id.to_s[top_property]
        return nil if (path.select { |x| x.id.to_s == r.id.to_s }).length > 0
        path << r
      end

      def traverse_path_to_root(parents, paths, path_i, tree=false, top_property=nil)
        return if parents.empty?
        recursions = [path_i]
        recurse_on_path = [false]

        # multiple paths
        if parents.length > 1 and not tree
          (parents.length - 1).times do
            paths << paths[path_i].clone
            recursions << (paths.length - 1)
            recurse_on_path << false
          end

          parents.each_index do |i|
            rec_i = recursions[i]
            recurse_on_path[i] = recurse_on_path[i] ||
                !append_if_not_there_already(paths[rec_i], parents[i], top_property).nil?
          end
        else
          path = paths[path_i]
          recurse_on_path[0] = !append_if_not_there_already(path, parents[0], top_property).nil?
        end

        recursions.each_index do |i|
          rec_i = recursions[i]
          path = paths[rec_i]
          p = path.last
          p.bring(parents: [:label, :definition]) if p.bring?(:parents)

          unless p.loaded_attributes.include?(:parents)
            # fail safely
            LOGGER.error("Property #{p.id.to_s} from #{p.submission.id.to_s} cannot load parents")
            return
          end

          if (!top_property || !p.id.to_s[top_property]) && recurse_on_path[i] && p.parents && p.parents.length > 0
            traverse_path_to_root(p.parents.dup, paths, rec_i, tree=tree, top_property=top_property)
          end
        end
      end

      def self.ontology_link(m)
        if m.class == self
          m.bring(:submission) if m.bring?(:submission)
          m.submission.bring(:ontology) if m.submission.bring?(:ontology)
          m.submission.ontology.bring(:acronym) if m.submission.ontology.bring?(:acronym)
        end
        "ontologies/#{m.submission.ontology.acronym}"
      end

      def self.partially_load_children(models, threshold, submission)
        ld = [:label, :definition]
        single_load = []
        query = self.in(submission).models(models)
        query.aggregate(:count, :children).all

        models.each do |prop|
          if prop.aggregates.nil?
            next
          end

          if prop.aggregates.first.value > threshold
            #too many load a page
            self.in(submission).models(single_load).include(children: [:label]).all
            page_children = self.where(parents: prop).include(ld).in(submission).page(1, threshold).all
            prop.instance_variable_set("@children", page_children.to_a)
            prop.loaded_attributes.add(:children)
          else
            single_load << prop
          end
        end

        if single_load.length > 0
          self.in(submission).models(single_load).include(ld << {children: [:label]}).all
        end
      end


    end

  end
end
