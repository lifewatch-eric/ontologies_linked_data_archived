require_relative "./test_ontology_common"
require "logger"

class TestOntologySubmission < LinkedData::TestOntologyCommon
  def setup
    @acronym = "SNOMED-TST"
    @name = "SNOMED-CT TEST"
    @ontologyFile = "./test/data/ontology_files/BRO_v3.2.owl"
    @id = 10
  end

  def teardown
    l = LinkedData::Models::OntologySubmission.all
    if l.length > 50
      raise ArgumentError, "Too many ontologies in triple store. TESTS WILL DELETE DATA"
    end
    l.each do |os|
      os.load
      os.delete
      o = os.ontology
      o.load
      o.delete
    end
  end
  


  def test_valid_ontology

    owl, bogus, user, status =  submission_dependent_objects("OWL", "bogus", "test_linked_models", "UPLOADED")

    os = LinkedData::Models::OntologySubmission.new
    assert (not os.valid?)

    os.acronym = @acronym
    os.submissionId = @id
    os.name = @name
    o = LinkedData::Models::Ontology.find(@acronym)
    if o.nil?
      os.ontology = LinkedData::Models::Ontology.new(:acronym => @acronym)
    else
      os.ontology = o 
    end
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(@acronym, @id, @ontologyFile) 
    os.uploadFilePath = uploadFilePath
    os.ontologyFormat = owl
    os.administeredBy = user
    os.ontology = bogus
    os.status = status
    assert os.valid?
  end
  
  def test_sanity_check_single_file_submission
    owl, bro, user, status =  submission_dependent_objects("OWL", "BRO", "test_linked_models", "UPLOADED")

    ont_submision =  LinkedData::Models::OntologySubmission.new({:acronym => "BRO", :submissionId => 1, :name => "Biomedical Resource Ontology"})
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository("BRO", 1, @ontologyFile) 
    ont_submision.uploadFilePath = uploadFilePath
    ont_submision.status = status
    assert (not ont_submision.valid?)
    assert_equal 3, ont_submision.errors.length
    assert_instance_of Array, ont_submision.errors[:ontology]
    assert_instance_of Array, ont_submision.errors[:administeredBy]
    assert_instance_of Array, ont_submision.errors[:ontologyFormat]
    ont_submision.ontologyFormat = owl
    ont_submision.administeredBy = user
    ont_submision.ontology = bro
    assert ont_submision.valid?
    assert_equal 0, ont_submision.errors.length
  end


  def test_sanity_check_zip
    teardown

    owl, rad, user, status =  submission_dependent_objects("OWL", "RADTEST", "test_linked_models", "UPLOADED")

    ont_submision =  LinkedData::Models::OntologySubmission.new({:acronym => "RADTEST", :submissionId => 1, :name => "RADTEST Bla"})
    ontologyFile = "./test/data/ontology_files/radlex_owl_v3.0.1.zip"
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository("RADTEST", 1, ontologyFile) 
    ont_submision.uploadFilePath = uploadFilePath
    ont_submision.ontologyFormat = owl
    ont_submision.administeredBy = user
    ont_submision.ontology = rad
    ont_submision.status = status
    assert (not ont_submision.valid?)
    assert_equal 1, ont_submision.errors.length
    assert_instance_of Hash, ont_submision.errors[:uploadFilePath][0]
    assert_instance_of Array, ont_submision.errors[:uploadFilePath][0][:options]
    assert_instance_of String, ont_submision.errors[:uploadFilePath][0][:message]
    assert (ont_submision.errors[:uploadFilePath][0][:options].length > 0)
    ont_submision.masterFileName = "does not exist"
    ont_submision.valid?
    assert_instance_of Hash, ont_submision.errors[:uploadFilePath][0]
    assert_instance_of Array, ont_submision.errors[:uploadFilePath][0][:options]
    assert_instance_of String, ont_submision.errors[:uploadFilePath][0][:message]

    #choose one from options.
    ont_submision.masterFileName = ont_submision.errors[:uploadFilePath][0][:options][0]
    assert ont_submision.valid?
    assert_equal 0, ont_submision.errors.length
  end

  def test_duplicated_file_names
    owl, dup, user, status =  submission_dependent_objects("OWL", "DUP", "test_linked_models", "UPLOADED")
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => "Bogus", :submissionId => 1, :name => "Bogus bla blu" })
    ontologyFile = "./test/data/ontology_files/ont_dup_names.zip"
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository("Bogus", 1, ontologyFile) 
    ont_submision.ontologyFormat = owl
    ont_submision.administeredBy = user
    ont_submision.ontology = dup
    assert (!ont_submision.valid?)
    assert_equal 2, ont_submision.errors.length
    assert_instance_of String, ont_submision.errors[:uploadFilePath][0]
    assert_instance_of String, ont_submision.errors[:status][0]
  end

  def test_submission_parse
    bro = LinkedData::Models::Ontology.find("BROTEST")
    if not bro.nil?
      sub = bro.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => "BROTEST", :submissionId => 1, :name => "Some Name" })
    assert (not ont_submision.valid?)
    assert_equal 5, ont_submision.errors.length
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository("BROTEST", 1, @ontologyFile) 
    ont_submision.uploadFilePath = uploadFilePath
    owl, bro, user, status =  submission_dependent_objects("OWL", "BROTEST", "test_linked_models", "UPLOADED")
    ont_submision.ontologyFormat = owl
    ont_submision.administeredBy = user
    ont_submision.ontology = bro
    ont_submision.status = status
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)
    uploaded = LinkedData::Models::SubmissionStatus.find("UPLOADED")
    uploded_ontologies = uploaded.submissions
    uploaded_ont = nil
    uploded_ontologies.each do |ont|
      ont.load
      if ont.acronym == "BROTEST"
        uploaded_ont = ont
      end
    end
    assert (not uploaded_ont.nil?)
    if not uploaded_ont.ontology.loaded?
      uploaded_ont.ontology.load
    end
    uploaded_ont.process_submission Logger.new(STDOUT)
  end

  def test_submission_parse_zip
    bro = LinkedData::Models::Ontology.find("RADTEST")
    if not bro.nil?
      sub = bro.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => "RADTEST", :submissionId => 1, :name => "Some Name for RADTEST" })
    assert (not ont_submision.valid?)
    assert_equal 5, ont_submision.errors.length
    ontologyFile = "./test/data/ontology_files/radlex_owl_v3.0.1.zip"
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository("RADTEST", 1,ontologyFile) 
    ont_submision.uploadFilePath = uploadFilePath
    owl, bro, user, status =  submission_dependent_objects("OWL", "RADTEST", "test_linked_models", "UPLOADED")
    ont_submision.ontologyFormat = owl
    ont_submision.administeredBy = user
    ont_submision.ontology = bro
    ont_submision.status = status
    assert (not ont_submision.valid?)
    assert_equal 1, ont_submision.errors[:uploadFilePath][0][:options].length
    ont_submision.masterFileName = ont_submision.errors[:uploadFilePath][0][:options][0].split("/")[-1]
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)
    uploaded = LinkedData::Models::SubmissionStatus.find("UPLOADED")
    uploded_ontologies = uploaded.submissions
    uploaded_ont = nil
    uploded_ontologies.each do |ont|
      ont.load
      if ont.acronym == "RADTEST"
        uploaded_ont = ont
      end
    end
    assert (not uploaded_ont.nil?)
    if not uploaded_ont.ontology.loaded?
      uploaded_ont.ontology.load
    end
    uploaded_ont.process_submission Logger.new(STDOUT)
  end

end

