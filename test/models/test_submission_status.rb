require_relative "../test_case"

class TestGroup < LinkedData::TestCase

  def test_submission_status_equal
    this = LinkedData::Models::SubmissionStatus.find('RDF').first
    that = LinkedData::Models::SubmissionStatus.find('RDF').first
    assert(!this.nil?, msg="SubmissionStatus failed to find RDF.")
    assert(!that.nil?, msg="SubmissionStatus failed to find RDF.")
    assert_equal(this, that, msg="SubmissionStatus 'RDF' failing equality test.")
    assert_equal(this, "RDF", msg="SubmissionStatus 'RDF' failing equality test.")
  end

end
