require_relative "./test_ontology_common"
require "logger"

class TestMapping < LinkedData::TestOntologyCommon
  def setup
    if LinkedData::Models::Mapping.all.length > 100
      puts "KB with too many mappings to run test. Is this pointing to a TEST KB?"
      raise Exception, "KB with too many mappings to run test. Is this pointing to a TEST KB?"
    end
    LinkedData::Models::Mapping.all do |m|
      m.delete
    end
    ontologies_parse()
  end

  def ontologies_parse()
    submission_parse("MappingOntTest1", "MappingOntTest1", "./test/data/ontology_files/BRO_v3.2.owl", 11)
    submission_parse("MappingOntTest2", "MappingOntTest2", "./test/data/ontology_files/CNO_05.owl", 22)
    submission_parse("MappingOntTest3", "MappingOntTest3", "./test/data/ontology_files/aero.owl", 33)
  end

  def submission_parse( acronym, name, ontologyFile, id)
    return if ENV["SKIP_PARSING"]

    bro = LinkedData::Models::Ontology.find(acronym)
    if not bro.nil?
      sub = bro.submissions || []
      if sub.length > 0
        return if sub[0].submissionStatus.parsed?
      end
      sub.each do |s|
        s.load unless s.loaded?
        s.delete
      end
      bro.delete
    end
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :submissionId => id})
    assert (not ont_submision.valid?)
    assert_equal 6, ont_submision.errors.length
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id, ontologyFile)
    ont_submision.uploadFilePath = uploadFilePath
    owl, bro, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED",name)
    bro.administeredBy = user
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.hasOntologyLanguage = owl
    ont_submision.ontology = bro
    ont_submision.submissionStatus = status
    assert (ont_submision.valid?)
    ont_submision.save

    assert_equal true, ont_submision.exist?(reload=true)
    uploaded = LinkedData::Models::SubmissionStatus.find("UPLOADED")
    uploded_ontologies = uploaded.submissions
    uploaded_ont = nil
    uploded_ontologies.each do |ont|
      ont.load unless ont.loaded?
      ont.ontology.load unless ont.ontology.loaded?
      if ont.ontology.acronym == acronym
        uploaded_ont = ont
      end
    end
    assert (not uploaded_ont.nil?)
    if not uploaded_ont.ontology.loaded?
      uploaded_ont.ontology.load
    end
    uploaded_ont.process_submission Logger.new(STDOUT)
  end

  def get_process(name)
    #just some user
    user = LinkedData::Models::User.all[0]

    #process
    ps = LinkedData::Models::MappingProcess.where({:name => name })
    ps.each do |p| 
      p.delete
    end
    p = LinkedData::Models::MappingProcess.new(:owner => user, :name => name)
    assert p.valid?
    p.save
    ps = LinkedData::Models::MappingProcess.where({:name => name })
    assert ps.length == 1
    return ps[0]
  end

  def test_multiple_mapping()

    process = get_process("LOOMTEST") 

    ont1 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest1" })[0]
    sub1 = ont1.latest_submission
    ont2 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest2" })[0]
    sub2 = ont2.latest_submission
    ont3 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest3" })[0]
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
      tm1 = LinkedData::Models::TermMapping.new(term: RDF::IRI.new(ont1_terms_uris[i]), ontology: ont1.resource_id)
      tm2 = LinkedData::Models::TermMapping.new(term: RDF::IRI.new(ont2_terms_uris[i]), ontology: ont2.resource_id)
      map = LinkedData::Models::Mapping.new(terms: [tm1, tm2], process: process)
      map.terms = [tm1,tm2]
      assert map.valid?
      map.save
    end

    assert LinkedData::Models::Mapping.all.length == ont1_terms_uris.length

    LinkedData::Models::Mapping.all.each do |map|
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
      tm2 = LinkedData::Models::TermMapping.new(term: ont2_terms_uris[i], ontology: ont2.resource_id)
      assert  tm2.exist?
      tm2 = LinkedData::Models::TermMapping.find(LinkedData::Models::TermMapping.term_mapping_id_generator(tm2))
      tm3 = LinkedData::Models::TermMapping.new(term: RDF::IRI.new(ont3_terms_uris[i]), ontology: ont3.resource_id)
      map = LinkedData::Models::Mapping.new(terms: [tm2, tm3], process: process)
      map.terms = [tm2,tm3]
      assert map.valid?
      map.save
    end

    assert LinkedData::Models::Mapping.all.length == (ont1_terms_uris.length + ont2_terms_uris.length)

    mappings = LinkedData::Models::Mapping.where terms: [{ ontology: ont1.resource_id }]
    binding.pry
    assert mappings.length == 11

    mappings = LinkedData::Models::Mapping.where terms: [{ ontology: ont2.resource_id }]
    assert mappings.length == 22

    mappings = LinkedData::Models::Mapping.where terms: [{ ontology: ont1.resource_id }, { ontology: ont2.resource_id }]
    assert mappings.length == 12

    mappings1 = LinkedData::Models::Mapping.where terms: [{ ontology: ont3.resource_id }]
    assert mappings.length == 11
  end
end
