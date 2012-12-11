require_relative "../test_case"

class TestOntologySubmission < LinkedData::TestCase
  def setup
    @acronym = "SNOMED-TST"
    @name = "SNOMED-CT TEST"
    @repoPath = "./test/data/ontology_files"
    @uploadFileName = "BRO_v3.2.owl"
    @id = 10
  end

  def teardown
    l = LinkedData::Models::OntologySubmission.where(:acronym => @acronym, :submissionId => @id)
    l.each do |o|
      os.delete
      o = os.ontology
      o.load
      o.delete
    end
  end

  def test_valid_ontology

    owl, bogus, user =  submission_dependent_objects("OWL", "bogus", "test_linked_models")

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
    os.repoPath = @repoPath
    os.uploadFileName = @uploadFileName
    os.ontologyFormat = owl
    os.administeredBy = user
    os.ontology = bogus
    assert os.valid?
  end
  
  def submission_dependent_objects(format,acronym,user_name)
    #ontology format
    LinkedData::Models::OntologyFormat.init
    owl = LinkedData::Models::OntologyFormat.where(:acronym => format)[0]
    assert_instance_of LinkedData::Models::OntologyFormat, owl

    #ontology
    LinkedData::Models::OntologyFormat.init
    ont = LinkedData::Models::Ontology.where(:acronym => acronym)
    LinkedData::Models::OntologyFormat.init
    assert(ont.length < 2)
    if ont.length == 0
      ont = LinkedData::Models::Ontology.new({:acronym => acronym})
    else
      ont = ont[0]
    end
    
    #user test_linked_models
    users = LinkedData::Models::User.where(:username => user_name)
    assert(users.length < 2)
    if users.length == 0
      user = LinkedData::Models::User.new({:username => user_name})
    else
      user = users[0]
    end
    return owl, ont, user 
  end
  
  def test_sanity_check_single_file_submission
    owl, bro, user =  submission_dependent_objects("OWL", "BRO", "test_linked_models")


    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => "BRO", :submissionId => 1, :name => "Biomedical Resource Ontology",
                             :repoPath => "./test/data/ontology_files", :uploadFileName => "BRO_v3.2.1_v3.2.1.owl"})
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
    
    owl, fma, user =  submission_dependent_objects("OWL", "FMA", "test_linked_models")

    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => "FMA", :submissionId => 1, :name => "FMA Bla",
                             :repoPath => "./test/data/ontology_files", :uploadFileName => "fma_3.1_owl_file_v3.1.zip"})
    ont_submision.ontologyFormat = owl
    ont_submision.administeredBy = user
    ont_submision.ontology = fma
    assert (not ont_submision.valid?)
    assert_equal 1, ont_submision.errors.length
    assert_instance_of Hash, ont_submision.errors[:uploadFileName][0]
    assert_instance_of Array, ont_submision.errors[:uploadFileName][0][:options]
    assert_instance_of String, ont_submision.errors[:uploadFileName][0][:message]
    assert (ont_submision.errors[:uploadFileName][0][:options].length > 0)
    ont_submision.masterFileName = "does not exist"
    ont_submision.valid?
    assert_instance_of Hash, ont_submision.errors[:uploadFileName][0]
    assert_instance_of Array, ont_submision.errors[:uploadFileName][0][:options]
    assert_instance_of String, ont_submision.errors[:uploadFileName][0][:message]

    #choose one from options.
    ont_submision.masterFileName = ont_submision.errors[:uploadFileName][0][:options][0]
    assert ont_submision.valid?
    assert_equal 0, ont_submision.errors.length
  end

  def test_duplicated_file_names
    owl, dup, user =  submission_dependent_objects("OWL", "DUP", "test_linked_models")
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => "Bogus", :submissionId => 1, :name => "Bogus bla blu",
                             :repoPath => "./test/data/ontology_files", :uploadFileName => "ont_dup_names.zip"})
    ont_submision.ontologyFormat = owl
    ont_submision.administeredBy = user
    ont_submision.ontology = dup
    assert (!ont_submision.valid?)
    assert_equal 1, ont_submision.errors.length
    assert_instance_of String, ont_submision.errors[:uploadFileName][0]
  end
end

