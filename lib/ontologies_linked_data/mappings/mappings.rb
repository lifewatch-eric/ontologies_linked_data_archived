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

  end
end
