
module LinkedData
  module Mappings
    module Batch
      def self.redis_cache
        unless @redis
          @redis = Redis.new(
              :host => LinkedData.settings.redis_host, 
              :port => LinkedData.settings.redis_port)
        end
        return @redis
      end
     end

    #TODO these methods are not really necessary
    def self.exist?(*term_mappings)
     id = LinkedData::Models::Mapping.mapping_id_generator_iris(*term_mappings)
      
     query =  
       """SELECT * WHERE { GRAPH ?g { <#{id.value}> a <#{LinkedData::Models::Mapping.type_uri}> }} LIMIT 1"""
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
    #TODO end this unnecesary methods

    class BatchProcess
      def initialize(process_name,logger,*onts)
        @process_name = process_name
        @logger = logger || Logger.new(STDOUT)
        process = get_process(process_name)
        @logger.info("using process id #{process.id.to_ntriples}")
        mappings_folder = File.join([LinkedData.settings.repository_folder,"mappings"])
        if not Dir.exist?(mappings_folder)
          FileUtils.mkdir_p(mappings_folder)
        end

        @ontologies = onts
        @process = process
        raise Exception "Only support for two ontologies" if @ontologies.length != 2
        @term_mappings = {}
        @existing_mappings_other_process = {}
        @existing_mappings_same_process = {}
        @new_mappings = {}
      end

      def get_process(name)
        #process
        ps = LinkedData::Models::MappingProcess.where({:name => name })
        if ps.length > 0
          return ps.first
        end

        #just some user
        user = LinkedData::Models::User.where(username: "ncbo").include(:username).first
        if user.nil?
          #probably devel environment - create it
          user = LinkedData::Models::User.new(:username => "ncbo", :email => "admin@bioontology.org" ) 
          user.password = "test"
          user.save
        end

        p = LinkedData::Models::MappingProcess.new(:owner => user, :name => name)
        p.save
        ps = LinkedData::Models::MappingProcess.where({:name => name }).to_a
        return ps[0]
      end

      def create_record_tuple(record_a,record_b)
        tuple = @record_tuple.new
        if record_a.acronym < record_b.acronym
          tuple.record_a = record_a
          tuple.record_b = record_b
        else
          tuple.record_a = record_b
          tuple.record_b = record_a
        end
        return tuple
      end

      def self.mappings_ontology_folder(ont)
        ont_folder = File.join([LinkedData.settings.repository_folder,ont.acronym,'mappings'])
        if not Dir.exist?(ont_folder)
          FileUtils.mkdir_p(ont_folder)
        end
        return ont_folder
      end

      def load_cache()
        #this load in memory all the mappings for the two ontologies
        #keep in the cache only the ones that have procs
      end

      def start()
        unless self.respond_to?(:run)
          raise ArgumentError, "Batch Process '#{@process_name}' needs to implement 'run()'"
        end

        t0 = Time.now 
        @logger.info("Starting batch ...")
        run()
        @logger.info("Total batch process time #{Time.now - t0} sec.")

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

