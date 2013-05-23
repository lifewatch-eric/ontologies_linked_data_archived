require_relative "../test_case"

class TestReview < LinkedData::TestCase

  def self.before_suite
    self.new("before_suite").teardown
  end

  def self.after_suite
    self.new("after_suite").teardown
  end

  def setup
    @user = LinkedData::Models::User.new(username: "test_user", email: "test_user@example.org", password: "password")
    @user.save if @user.valid?
    @ont = LinkedData::Models::Ontology.new(acronym: "TST", name: "Test Ontology", administeredBy: [@user])
    @ont.save if @ont.valid?
    @ont = LinkedData::Models::Ontology.find("TST").first
    @review_params = {
        :creator => @user,
        :created => DateTime.new,
        :body => "This is a test review.",
        :ontologyReviewed => @ont,
        :usabilityRating => 0,
        :coverageRating => 0,
        :qualityRating => 0,
        :formalityRating => 0,
        :correctnessRating => 0,
        :documentationRating => 0,
    }
  end

  def teardown
    delete_goo_models(LinkedData::Models::Review.where.all)
    delete_goo_models(LinkedData::Models::Ontology.where.all)
    delete_goo_models(LinkedData::Models::User.where.all)
    @review_params = nil
    @ont = nil
    @user = nil
  end

  def test_review_creator
    model_creator_test(LinkedData::Models::Review, @user) # method from test_case.rb
  end

  def test_review_created
    # Ensure there is no 'created' parameter so the model creates a default value.
    @review_params.delete :created
    model_created_test(LinkedData::Models::Review.new(@review_params)) # method from test_case.rb
  end

  def test_valid_review
    # The setup parameters should be valid
    r = LinkedData::Models::Review.new(@review_params)
    assert r.valid?
    r = LinkedData::Models::Review.new
    assert (not r.valid?)
    # Not valid because not all attributes are present
    r.body = @review_params[:body]
    r.created = @review_params[:created]
    r.usabilityRating = @review_params[:usabilityRating]
    r.coverageRating = @review_params[:coverageRating]
    r.qualityRating = @review_params[:qualityRating]
    r.formalityRating = @review_params[:formalityRating]
    r.correctnessRating = @review_params[:correctnessRating]
    r.documentationRating = @review_params[:documentationRating]
    assert (not r.valid?)
    # Fix typing
    r.creator = @review_params[:creator]
    r.ontologyReviewed = @review_params[:ontologyReviewed]
    assert r.valid?
  end

  def test_review_lifecycle
    model_lifecycle_test(LinkedData::Models::Review.new(@review_params))
  end

end
