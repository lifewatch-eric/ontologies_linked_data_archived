require "set"

module LinkedData
  module Models
    class ClassAttributeNotLoaded < StandardError
    end

    class Class < LinkedData::Models::Base
      model :class,
            :namespace => :owl

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

      # Hypermedia settings
      link_to LinkedData::Hypermedia::Link.new("self", "/ontologies/:submission.ontology.acronym/classes/:resource_id.value"),
              LinkedData::Hypermedia::Link.new("children", "/ontologies/:submission.ontology.acronym/classes/:resource_id.value/children"),
              LinkedData::Hypermedia::Link.new("parents", "/ontologies/:submission.ontology.acronym/classes/:resource_id.value/parents"),
              LinkedData::Hypermedia::Link.new("descendents", "/ontologies/:submission.ontology.acronym/classes/:resource_id.value/descendents"),
              LinkedData::Hypermedia::Link.new("ancestors", "/ontologies/:submission.ontology.acronym/classes/:resource_id.value/ancestors")


      def self.where(*args)
        params = args[0].dup
        missing_labels_generation = params.delete :missing_labels_generation

        inject_subproperty_query_option(params)
        super(params) rescue binding.pry
      end

      def self.find(*args)
        args[-1][:query_options] = { rules: :SUBP }
        super(*args)
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
          if params[:load_attrs] == :defined || !(params[:load_attrs] & [:prefLabel, :synonym, :definition]).empty?
             params[:query_options] = { rules: :SUBP } if !params.include? :query_options
          end
        end
      end
    end

  end
end
