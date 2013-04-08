require_relative "./test_ontology_common"
require "logger"

class TestNote < LinkedData::TestOntologyCommon
  def setup
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

  def test_mappings()
    assert 1==1
  end
end
