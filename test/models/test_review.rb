require_relative "../test_case"

class TestReview < LinkedData::TestCase

  def setup
    @user = LinkedData::Models::User.new(username: "paul", email: "paul@example.org")
    @user.save
    @ontology = LinkedData::Models::Ontology.new(acronym: "SNOMED-TST", name: "SNOMED CT Test", administeredBy: @user)
    @ontology.save
  end

  def teardown
    @user.delete
    @ontology.delete
  end

  def test_valid_review
    r = LinkedData::Models::Review.new
    assert (not r.valid?)

    # Not valid because not all attributes are present
    r.body = "This is a test review"
    r.created = DateTime.parse("2012-10-04T07:00:00.000Z")
    assert (not r.valid?)

    # Still not valid because not all attributes are typed properly
    r.creator = "paul"
    r.ontologyReviewed = "SNOMED"
    assert (not r.valid?)

    # Fix typing
    r.creator = @user
    r.ontologyReviewed = @ontology
    assert r.valid?
  end

  def test_review_lifecycle
    r = LinkedData::Models::Review.new({
        :creator => @user,
        :created => DateTime.parse("2012-10-04T07:00:00.000Z"),
        :body => "This is a test review",
        :ontologyReviewed => @ontology
      })

    assert_equal false, r.exist?(reload=true)
    r.save
    assert_equal true, r.exist?(reload=true)
    r.delete
    assert_equal false, r.exist?(reload=true)
  end

  def test_review_default_datetime
    r = LinkedData::Models::Review.new
    #this is nil unless it is saved
    assert r.created.nil?
  end
end
