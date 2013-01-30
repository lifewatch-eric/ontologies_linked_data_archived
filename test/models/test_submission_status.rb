require_relative "../test_case"

class TestSubmissionStatus < LinkedData::TestCase
  def setup
  end

  def teardown
    ofs = LinkedData::Models::SubmissionStatus.all
    ofs.each do |of|
      of.load
      of.delete
    end
  end

  def test_submission_status
    teardown
    LinkedData::Models::SubmissionStatus.init
    #eventually change this to READY
    parsed_status = LinkedData::Models::SubmissionStatus.find("RDF")
    assert(parsed_status.parsed?)
    parsed_status = LinkedData::Models::SubmissionStatus.find("UPLOADED")
    assert(!parsed_status.parsed?)
    assert (LinkedData::Models::SubmissionStatus.all.length > 5)
  end

end
