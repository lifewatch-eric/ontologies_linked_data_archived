require_relative "../test_case"

class TestProvisionalClass < LinkedData::TestCase

  def setup
    _delete

    @user = LinkedData::Models::User.new({username: "Test User", email: "tester@example.org", password: "password"})
    assert @user.valid?, "Invalid User object #{@user.errors}"
    @user.save

    ont_count, ont_names, ont_models = create_ontologies_and_submissions(ont_count: 1, submission_count: 1)
    @ontology = ont_models.first
    @ontology.bring(:name)
    @ontology.bring(:acronym)
    @submission = @ontology.bring(:submissions).submissions.first

    @provisional_class = LinkedData::Models::ProvisionalClass.new({label: "Test Provisional Class", creator: @user})
    assert @provisional_class.valid?, "Invalid ProvisionalClass object #{@provisional_class.errors}"
    @provisional_class.save
  end

  def _delete
    delete_ontologies_and_submissions
    user = LinkedData::Models::User.find("Test User").first
    user.delete unless user.nil?
  end

  def test_provisional_class_lifecycle
    label = "Test Provisional Class Lifecycle"
    pc = LinkedData::Models::ProvisionalClass.new({label: label, :creator => @user})

    # Before save
    assert_equal LinkedData::Models::ProvisionalClass.where(label: label).all.count, 0
    assert_equal false, pc.exist?(reload=true)
    
    pc.save

    # After save
    assert_equal LinkedData::Models::ProvisionalClass.where(label: label).all.count, 1
    assert_equal true, pc.exist?(reload=true)
    
    pc.delete

    # After delete
    assert_equal LinkedData::Models::ProvisionalClass.where(label: label).all.count, 0
    assert_equal false, pc.exist?(reload=true)
  end

  def test_provisional_class_valid
    _delete

    pc = LinkedData::Models::ProvisionalClass.new
    assert (not pc.valid?)

    # Not valid (missing required attributes).
    pc.definition = ["Definition 1", "Definition 2"]
    assert (not pc.valid?), "#{pc.errors}"

    # Valid (required attributes initialized).
    pc.label = "Test Provisional Class"
    pc.creator = @user
    assert pc.valid?, "#{pc.errors}"
  end

  def test_provisional_class_retrieval
    creators = ["Test User 0", "Test User 1", "Test User 2"]
    pc_array = Array.new(3) { LinkedData::Models::ProvisionalClass.new }
    pc_array.each_with_index do |pc, i|      
      pc.label = "Test PC #{i}"
      pc.creator = LinkedData::Models::User.new({username: creators[i], email: "tester@example.org", password: "password"}).save
      pc.save
      assert pc.valid?, "#{pc.errors}"
    end

    # Retrieve a particular ProvisionalClass
    pc1 = LinkedData::Models::ProvisionalClass.where(label: "Test PC 2").all
    assert_equal pc1.length, 1
    
    # Retrieve the same ProvisionalClass another way
    pc2 = LinkedData::Models::ProvisionalClass.where(creator: [username: "Test User 2"]).all
    assert_equal pc1.first.id.to_s, pc2.first.id.to_s

    pc_array.each do |pc|
      pc.delete
    end
  end

  def test_provisional_class_filter_by_creator
    username = "User Testing Filtering"
    user = LinkedData::Models::User.new({username: username, email: "tester@example.org", password: "password"})
    user.save
    assert user.valid?, "#{user.errors}" 

    pc_array = Array.new(3) { LinkedData::Models::ProvisionalClass.new }
    pc_array.each_with_index do |pc, i|
      pc.label = "PC Testing Filtering #{i}"
      pc.creator = user
      pc.save
      assert pc.valid?, "#{pc.errors}"
    end

    user = LinkedData::Models::User.find(username).include(:provisionalClasses).first
    assert_equal user.provisionalClasses.count, 3

    pcs = LinkedData::Models::ProvisionalClass.where(creator: [username: username]).all
    assert_equal pcs.count, 3

    pc_array.each do |pc|
      pc.delete
    end
    user.delete
  end

  def test_provisional_class_synonym
    syns = ["Test Synonym 1", "Test Synonym 2", "Test Synonym 3"]
    pc = @provisional_class
    pc.synonym = syns
    assert pc.valid?, "#{pc.errors}"
    pc.save
    assert pc.synonym.length == 3
    assert_equal(pc.synonym.first, syns.first)
    pc.delete
  end

  def test_provisional_class_description
    defs = ["Some definition", "Some other definition"]
    pc = @provisional_class
    pc.definition = defs
    assert pc.valid?, "#{pc.errors}"
    pc.save
    assert pc.definition.length == 2
    assert_equal(pc.definition.first, defs.first)
    pc.delete
  end

  def test_provisional_class_subclass_of
    pc = @provisional_class
    
    # Invalid URI
    pc.subclassOf = "Invalid subclassOf URI"
    assert (not pc.valid?)
    assert_equal(false, pc.errors[:subclassOf].nil?)

    # Valid URI
    pc.subclassOf = RDF::IRI.new("http://valid.uri.com")
    assert pc.valid?
    assert_equal(true, pc.errors[:subclassOf].nil?)
    pc.delete
  end

  def test_provisional_class_created
    pc = @provisional_class

    # created should have a default value.
    assert (not pc.created.nil?)
    assert pc.valid?, "#{pc.errors}"
    pc.save
    assert pc.created.instance_of?(DateTime)
    pc.delete
  end

  def test_provisional_class_permanent_id
    pc = @provisional_class
    
    # Invalid URI
    pc.permanentId = "Invalid permanentId URI"
    assert (not pc.valid?)
    assert_equal(false, pc.errors[:permanentId].nil?)

    # Valid URI
    pc.permanentId = RDF::IRI.new("http://valid.uri.com")
    assert pc.valid?
    assert_equal(true, pc.errors[:permanentId].nil?)
    pc.delete
  end

  def test_provisional_class_note_id
    pc = @provisional_class
    
    # Invalid URI
    pc.noteId = "Invalid noteId URI"
    assert (not pc.valid?)
    assert_equal(false, pc.errors[:noteId].nil?)

    # Valid URI
    pc.noteId = RDF::IRI.new("http://valid.uri.com")
    assert pc.valid?
    assert_equal(true, pc.errors[:noteId].nil?)
    pc.delete
  end

  def test_provisional_class_ontology
    pc = @provisional_class
    pc.ontology = @ontology
    assert pc.valid?, "#{pc.errors}"
    assert_equal(true, pc.ontology.acronym == "TEST-ONT-0")
    assert_equal(true, pc.ontology.name == "TEST-ONT-0 Ontology")
    pc.delete
  end

  def test_provisional_class_search_indexing
    pc = @provisional_class
    pc.ontology = @ontology
    pc.index
    params = {"fq" => "provisional:true"}
    resp = LinkedData::Models::Ontology.search(pc.label, params)
    assert_equal 1, resp["response"]["numFound"]
    assert_equal pc.label, resp["response"]["docs"][0]["prefLabel"]
    pc.delete
  end

end
