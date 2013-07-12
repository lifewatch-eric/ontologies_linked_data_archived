require_relative "batch"
require_relative "loom"
require_relative "cuis"
require_relative "same_uris"
require_relative "xref"

module LinkedData
module Mappings

  def self.mapping_key(id)
    return "mappings:mapping:#{id.to_s}"
  end

  def self.mapping_procs_key(id)
    return "mappings:mapping:procs:#{id.to_s}"
  end

  def self.term_mapping_key(id)
    return "mappings:terms:#{id.to_s}"
  end

  def self.create_term_mapping(term_uris,acronym)
    id_term_mapping = LinkedData::Models::TermMapping.term_mapping_id_generator(term_uris,acronym)
    return id_term_mapping if exist_term_mapping?(term_uris,acronym)
    term = LinkedData::Models::TermMapping.new
    term.ontology = LinkedData::Models::Ontology.find(acronym).include(:acronym).first
    term.term = term_uris
    term.save unless term.exist?
    term_m_key = term_mapping_key(id_term_mapping)
    redis = LinkedData::Mappings::Batch.redis_cache
    redis.hset term_m_key, "ontology", acronym
    redis.hset term_m_key, "terms", term_uris.map { |x| x.to_s }.join("|split|")
    return id_term_mapping
  end

  def self.exist_term_mapping?(term_uris,ontology)
    redis = LinkedData::Mappings::Batch.redis_cache
    id_term_mapping = LinkedData::Models::TermMapping.term_mapping_id_generator(term_uris,ontology)
    return redis.exists(term_mapping_key(id_term_mapping))
  end

  def self.create_mapping(term_mapping_ids)
    id_mapping = LinkedData::Models::Mapping.mapping_id_generator_iris(*term_mapping_ids)
    return id_mapping if exist_mapping?(term_mapping_ids)
    mapping = LinkedData::Models::Mapping.new
    term_mappings = term_mapping_ids.map { |x| LinkedData::Models::TermMapping.read_only(id: x) }
    mapping.terms = term_mappings
    mapping.save unless mapping.exist?
    redis = LinkedData::Mappings::Batch.redis_cache
    redis.rpush(mapping_key(id_mapping), term_mapping_ids)
    return id_mapping
  end
  
  def self.exist_mapping?(term_mapping_ids)
    redis = LinkedData::Mappings::Batch.redis_cache
    id_mapping = LinkedData::Models::Mapping.mapping_id_generator_iris(*term_mapping_ids)
    return redis.exists(mapping_key(id_mapping))
  end

  def self.connect_mapping_process(mapping_id,process)
    redis = LinkedData::Mappings::Batch.redis_cache
    unless redis.exists(mapping_key(mapping_id))
      raise ArgumentError, "Mapping id #{mapping_id.to_ntriples} not found"
    end
    map_proc_key = mapping_procs_key(mapping_id)
    procs = redis.lrange(map_proc_key,0,-1)
    return if procs.index(process.id.to_s)
    mapping = LinkedData::Models::Mapping.find(mapping_id)
                                            .include(:process)
                                            .include(:terms)
                                            .first
    map_procs = mapping.process.dup
    return if map_procs.map { |x| x.id.to_s }.index(process.id.to_s)
    map_procs << process
    mapping.process = map_procs
    mapping.save
    redis.rpush(map_proc_key, [process.id.to_s])
    nil
  end

end
end
