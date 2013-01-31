require_relative "../test_case"

class TestReview < LinkedData::TestCase

  def setup
    @user = LinkedData::Models::User.new(username: "test_user", email: "test_user@example.org")
    @user.save
    @ontology = LinkedData::Models::Ontology.new(acronym: "TST", name: "Test Ontology", administeredBy: @user)
    @ontology.save
    @review_params = {
        :creator => @user,
        :created => DateTime.new,
        :body => "This is a test review.",
        :ontologyReviewed => @ontology
    }
    @r = LinkedData::Models::Review.new(@review_params)
  end

  def teardown
    delete_goo_models(LinkedData::Models::Review.all)
    delete_goo_models(LinkedData::Models::Ontology.all)
    delete_goo_models(LinkedData::Models::User.all)
    delete_goo_models(LinkedData::Models::UserRole.all)
    @ontology = nil
    @user = nil
  end

  def test_review_creator
    model_creator_test(LinkedData::Models::Review, @user) # method from test_case.rb
  end

  def test_review_created
    # Ensure there is no 'created' parameter so the model creates a default value.
    @review_params.delete :created
    r = LinkedData::Models::Review.new(@review_params)
    model_created_test(r) # method from test_case.rb
  end

  def test_valid_review
    # The setup parameters should be valid
    r = LinkedData::Models::Review.new(@review_params)
    assert r.valid?
    r = LinkedData::Models::Review.new
    assert (not r.valid?)
    # Not valid because not all attributes are present
    r.body = "This is a test review"
    r.created = DateTime.new
    assert (not r.valid?)
    # Still not valid because not all attributes are typed properly
    r.creator = "string" # must be instance of LinkedData::Models::User
    r.ontologyReviewed = "TST" # must be instance of LinkedData::Models::Ontology
    assert (not r.valid?)
    # Fix typing
    r.creator = @user
    r.ontologyReviewed = @ontology
    assert r.valid?
  end

  def test_review_lifecycle
    r = LinkedData::Models::Review.new(@review_params)
    model_lifecycle_test(r)
  end

end
