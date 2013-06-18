require_relative "./test_ontology_common"
require "logger"

class TestMapping < LinkedData::TestOntologyCommon
  def setup
    if LinkedData::Models::Mapping.all.length > 100
      puts "KB with too many mappings to run test. Is this pointing to a TEST KB?"
      raise Exception, "KB with too many mappings to run test. Is this pointing to a TEST KB?"
    end
    LinkedData::Models::MappingProcess.all do |m|
      m.delete
    end
    LinkedData::Models::TermMapping.all do |m|
      m.delete
    end
    LinkedData::Models::Mapping.all do |m|
      m.delete
    end
    ontologies_parse()
  end

  def ontologies_parse()
    return
    submission_parse("MappingOntTest1", "MappingOntTest1", "./test/data/ontology_files/BRO_v3.2.owl", 11)
    submission_parse("MappingOntTest2", "MappingOntTest2", "./test/data/ontology_files/CNO_05.owl", 22)
    submission_parse("MappingOntTest3", "MappingOntTest3", "./test/data/ontology_files/aero.owl", 33)
  end

  def get_process(name)
    #just some user
    user = LinkedData::Models::User.where.include(:username).all[0]

    #process
    ps = LinkedData::Models::MappingProcess.where({:name => name })
    ps.each do |p| 
      p.delete
    end
    p = LinkedData::Models::MappingProcess.new(:owner => user, :name => name)
    assert p.valid?
    p.save
    ps = LinkedData::Models::MappingProcess.where({:name => name }).to_a
    assert ps.length == 1
    return ps[0]
  end

  def test_multiple_mapping()

    process = get_process("LOOMTEST") 

    ont1 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest1" }).to_a[0]
    sub1 = ont1.latest_submission
    ont2 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest2" }).to_a[0]
    sub2 = ont2.latest_submission
    ont3 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest3" }).to_a[0]
    sub3 = ont3.latest_submission
    LinkedData::Models::Mapping.all.each do |occ|
      occ.delete
    end
    LinkedData::Models::TermMapping.all.each do |tm|
      tm.delete
    end

    ont1_terms_uris = ["http://bioontology.org/ontologies/Activity.owl#Activity",
 "http://bioontology.org/ontologies/Activity.owl#Biospecimen_Management",
 "http://bioontology.org/ontologies/Activity.owl#Community_Engagement",
 "http://bioontology.org/ontologies/Activity.owl#Deprecated_Activity",
 "http://bioontology.org/ontologies/Activity.owl#Gene_Therapy",
 "http://bioontology.org/ontologies/Activity.owl#Health_Services",
 "http://bioontology.org/ontologies/Activity.owl#Heath_Services",
 "http://bioontology.org/ontologies/Activity.owl#IRB",
 "http://bioontology.org/ontologies/Activity.owl#Medical_Device_Development",
 "http://bioontology.org/ontologies/Activity.owl#Novel_Therapeutics",
 "http://bioontology.org/ontologies/Activity.owl#Regulatory_Compliance"]

    ont2_terms_uris = ["http://purl.obolibrary.org/obo/SBO_0000512",
 "http://purl.obolibrary.org/obo/SBO_0000513",
 "http://purl.obolibrary.org/obo/SBO_0000514",
 "http://purl.obolibrary.org/obo/SBO_0000515",
 "http://purl.obolibrary.org/obo/SBO_0000516",
 "http://purl.obolibrary.org/obo/SBO_0000517",
 "http://purl.obolibrary.org/obo/SBO_0000518",
 "http://purl.obolibrary.org/obo/SBO_0000519",
 "http://purl.obolibrary.org/obo/SBO_0000520",
 "http://purl.obolibrary.org/obo/SBO_0000521",
 "http://purl.obolibrary.org/obo/SBO_0000522"]
      
      
    ont3_terms_uris = ["http://purl.obolibrary.org/obo/IAO_0000178",
 "http://purl.obolibrary.org/obo/IAO_0000179",
 "http://purl.obolibrary.org/obo/IAO_0000180",
 "http://purl.obolibrary.org/obo/IAO_0000181",
 "http://purl.obolibrary.org/obo/IAO_0000182",
 "http://purl.obolibrary.org/obo/IAO_0000183",
 "http://purl.obolibrary.org/obo/IAO_0000184",
 "http://purl.obolibrary.org/obo/IAO_0000185",
 "http://purl.obolibrary.org/obo/IAO_0000186",
 "http://purl.obolibrary.org/obo/IAO_0000225",
 "http://purl.obolibrary.org/obo/IAO_0000300"]

    ont1_terms_uris.each_index do |i|
      tm1 = LinkedData::Models::TermMapping.new(term: [RDF::IRI.new(ont1_terms_uris[i])], ontology: ont1)
      tm1.save
      tm2 = LinkedData::Models::TermMapping.new(term: [RDF::IRI.new(ont2_terms_uris[i])], ontology: ont2)
      tm2.save
      map = LinkedData::Models::Mapping.new(terms: [tm1, tm2], process: [process])
      map.terms = [tm1,tm2]
      assert map.valid?
      map.save
    end

    assert LinkedData::Models::Mapping.all.length == ont1_terms_uris.length

    mappings = LinkedData::Models::Mapping.where.include(terms:[ ontology: :acronym]).to_a
    mappings.each do |map|                                           
      ont1_index = 0
      ont2_index = 1
      if map.terms[0].ontology.acronym != "MappingOntTest1"
        ont1_index = 1
        ont2_index = 0
      end
      i1 = ont1_terms_uris.index(map.terms[ont1_index])
      i2 = ont2_terms_uris.index(map.terms[ont2_index])
      assert i1 == i2
    end

    ont2_terms_uris.each_index do |i|
      #reusing TermMapping
      tm2 = LinkedData::Models::TermMapping.new(term: [ont2_terms_uris[i]], ontology: ont2)
      assert  tm2.exist?
      tm2 = LinkedData::Models::TermMapping.find(LinkedData::Models::TermMapping.term_mapping_id_generator(tm2)).first
      tm3 = LinkedData::Models::TermMapping.new(term: [RDF::IRI.new(ont3_terms_uris[i])], ontology: ont3)
      tm3.save
      map = LinkedData::Models::Mapping.new(terms: [tm2, tm3], process: [process])
      map.terms = [tm2,tm3]
      assert map.valid?
      map.save
    end

    assert LinkedData::Models::Mapping.all.length == (ont1_terms_uris.length + ont2_terms_uris.length)

    mappings = LinkedData::Models::Mapping.where(terms: [ ontology: ont1]).to_a
    assert mappings.length == 11

    mappings = LinkedData::Models::Mapping.where(terms: [ ontology: ont2 ]).to_a
    assert mappings.length == 22

    mappings = LinkedData::Models::Mapping.where(terms: [ ontology: ont1 ])
                                            .and(terms: [ ontology: ont2 ]).to_a
    assert mappings.length == 11

    mappings = LinkedData::Models::Mapping.where(terms: [ ontology: ont3 ]).to_a
    assert mappings.length == 11
  end
end
