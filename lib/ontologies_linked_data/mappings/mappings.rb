module LinkedData
  module Mappings

    def self.exist?(*iris)
     values = (iris.map { |i| i.value}).sort
     id = LinkedData::Models::Mapping.mapping_id_generator_iris(values)
      
     query =  """SELECT * WHERE { GRAPH ?g { <#{id.value}> a <#{LinkedData::Models::Mapping.type_uri}> }} LIMIT 1"""
     epr = Goo.store(@store_name)
     epr.query(query).each_solution do |sol|
       return true
     end
     return false
    end

    #it only creates the id
    def self.create_or_retrieve_mapping(*iris)
     values = (iris.map { |i| i.value}).sort
     id = LinkedData::Models::Mapping.mapping_id_generator_iris(values)
     if Mappings.exist?(id)
       return LinkedData::Models::Mapping.find(id)
     end
     insert = """INSERT DATA { GRAPH <#{LinkedData::Models::Mapping.type_uri}> {  <#{id.value}> a <#{LinkedData::Models::Mapping.type_uri}> }}"""
     epr = Goo.store(@store_name)
     epr.update(insert)
     return  LinkedData::Models::Mapping.find(id)
    end
  end
end
