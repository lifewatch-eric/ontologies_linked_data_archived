require_relative "../test_case"
require "logger"

class TestClassModel < LinkedData::TestCase
  def setup
  end

  def init_test_ontology(acr)
    ont = LinkedData::Models::Ontology.find(acr)
    if not ont.nil?
      sub = ont.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
      ont.delete
    end
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => acr, :submissionId => 1, :name => "Some Name" })
    assert (not ont_submision.valid?)
    assert_equal 5, ont_submision.errors.length
    file_path = "./test/data/ontology_files/custom_properties.owl" 
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acr, 1, file_path) 
    ont_submision.uploadFilePath = uploadFilePath
    owl, ont, user, status =  submission_dependent_objects("OWL", acr, "test_linked_models", "UPLOADED")
    ont_submision.ontologyFormat = owl
    ont_submision.administeredBy = user
    ont_submision.ontology = ont
    ont_submision.status = status
    ont_submision.prefLabelProperty = RDF::IRI.new("http://bioportal.bioontology.org/ontologies/msotes#myPrefLabel")
    ont_submision.synonymProperty = RDF::IRI.new("http://bioportal.bioontology.org/ontologies/msotes#mySynonymLabel")
    ont_submision.definitionProperty = RDF::IRI.new("http://bioportal.bioontology.org/ontologies/msotes#myDefinition")
    ont_submision.authorProperty = RDF::IRI.new("http://bioportal.bioontology.org/ontologies/msotes#myAuthor")
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)
    uploaded = LinkedData::Models::SubmissionStatus.find("UPLOADED")
    uploded_ontologies = uploaded.submissions
    uploaded_ont = nil
    uploded_ontologies.each do |ont|
      ont.load
      if ont.acronym == acr
        uploaded_ont = ont
      end
    end
    assert (not uploaded_ont.nil?)
    if not uploaded_ont.ontology.loaded?
      uploaded_ont.ontology.load
    end
    uploaded_ont.process_submission Logger.new(STDOUT)
  end
  
  def test_terms_custom_props
    acr = "CSTPROPS"
    init_test_ontology acr
    os = LinkedData::Models::OntologySubmission.find(acr + '+' + 1.to_s)
    os_classes = os.classes
    os_classes.each do |c|
      puts "#{c.id} #{c.prefLabel}"
    end
    os.ontology.load
    os.ontology.delete
    os.delete
  end
end
