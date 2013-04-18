module LinkedData
  module Mappings
    def self.exist?(*term_mappings)
     id = LinkedData::Models::Mapping.mapping_id_generator_iris(*term_mappings)
      
     query =  """SELECT * WHERE { GRAPH ?g { <#{id.value}> a <#{LinkedData::Models::Mapping.type_uri}> }} LIMIT 1"""
     epr = Goo.store(@store_name)
     epr.query(query).each_solution do |sol|
       return true
     end
     return false
    end

    #it only creates the id
    def self.create_or_retrieve_mapping(*term_mappings)
     id = LinkedData::Models::Mapping.mapping_id_generator_iris(*term_mappings)
     if Mappings.exist?(*term_mappings)
       return LinkedData::Models::Mapping.find(id)
     end
     assign = []
     term_mappings.each do |tm|
       assign << LinkedData::Models::TermMapping.find(tm.resource_id) || tm
     end
     m = LinkedData::Models::Mapping.new(terms: term_mappings)
     m.save
     return  m
    end

    def self.update_mapping_process(map,pro)
      map.process.each do |p|
        return p.id == pro.id
      end
      procs = map.process.dup << pro
      map.process = procs
      map.save
    end

    class BatchProcess
      def initialize(process,*onts)
        @onts = onts
        @process = process
        raise Exception "Only support for two ontologies" if onts.length != 2
        @term_mappings = {}
        @existing_mappings_other_process = {}
        @existing_mappings_same_process = {}
        @new_mappings = {}
      end

      def load_cache()
        #this load in memory all the mappings for the two ontologies
        #keep in the cache only the ones that have procs
      end

      def start()
      end

      def new_mapping(*term_mappings)
        id = LinkedData::Models::Mapping.mapping_id_generator_iris(*term_mappings)
        if @existing_mappings_same_process.include?(id)
          return
        end
        if @existing_mappings_other_process.include?(id)
          #update process
           m=@existing_mappings_other_process[id]
           m.process = (m.process.dup << @process)
           m.save
           return
        end
        term_mappings_in = []
        term_mappings.each do |tm|
          id_tm = TermMapping.term_mapping_id_generator(tm)
          term_mappings_in << @term_mappings.include?(id_tm) ? @term_mappings[id_tm] : tm 
        end

        term_mappings_in.each do |tm|
          unless tm.persistent?
            tm.save
            @term_mappings[tm.id] = tm
          end
        end
        mapping = create_or_retrieve_mapping(term_mappings_in)
        @existing_mappings_same_process[mapping.id] = mapping
      end

      def finish()
        #place to detect deletes
      end

    end
  end
end
