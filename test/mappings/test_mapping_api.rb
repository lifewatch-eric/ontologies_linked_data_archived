require_relative "../models/test_ontology_common"
require "logger"

class TestMappingAPI < LinkedData::TestOntologyCommon

    ONT1_TERMS = ["http://bioontology.org/ontologies/Activity.owl#Activity",
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

    ONT2_TERMS = ["http://purl.obolibrary.org/obo/SBO_0000512",
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


    ONT3_TERMS = ["http://purl.obolibrary.org/obo/IAO_0000178",
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

  #TODO this has be replace by Paul's data genrator
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
    assert_equal 5, ont_submision.errors.length
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

  def ontologies_parse()
    submission_parse("MappingOntTest1", "MappingOntTest1", "./test/data/ontology_files/BRO_v3.2.owl", 11)
    submission_parse("MappingOntTest2", "MappingOntTest2", "./test/data/ontology_files/CNO_05.owl", 22)
    submission_parse("MappingOntTest3", "MappingOntTest3", "./test/data/ontology_files/aero.owl", 33)
  end

  def test_mapping_create
    LinkedData::Models::Mapping.all.each do |m|
      m.delete
    end
    LinkedData::Models::TermMapping.all.each do |tm|
      tm.delete
    end
    ont1 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest1" })[0]
    ont2 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest2" })[0]
    ont3 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest3" })[0]

    ONT1_TERMS.each_index do |i1|
      term1 = RDF::IRI.new(ONT1_TERMS[i1])
      term2 = RDF::IRI.new(ONT2_TERMS[i1])
      mapping_terms =  [LinkedData::Models::TermMapping.new(term: RDF::IRI.new(term1), ontology: ont1.resource_id),
        LinkedData::Models::TermMapping.new(term: RDF::IRI.new(term2), ontology: ont2.resource_id) ]
      assert !LinkedData::Mappings.exist?(*mapping_terms)
      assert LinkedData::Models::Mapping, LinkedData::Mappings.create_or_retrieve_mapping(*mapping_terms)
    end
    assert LinkedData::Models::Mapping.all.count == 11

    #nothing must be created if repeated the process
    ONT1_TERMS.each_index do |i1|
      term1 = RDF::IRI.new(ONT1_TERMS[i1])
      term2 = RDF::IRI.new(ONT2_TERMS[i1])
      mapping_terms =  [LinkedData::Models::TermMapping.new(term: RDF::IRI.new(term1), ontology: ont1.resource_id),
        LinkedData::Models::TermMapping.new(term: RDF::IRI.new(term2), ontology: ont2.resource_id) ]
      assert LinkedData::Mappings.exist?(*mapping_terms)
      assert LinkedData::Models::Mapping, LinkedData::Mappings.create_or_retrieve_mapping(*mapping_terms)
    end
    assert LinkedData::Models::Mapping.all.count == 11

    LinkedData::Models::Mapping.all.each do |m|
      m.delete
    end
  end
end
