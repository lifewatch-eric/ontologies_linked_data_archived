require_relative "../../test_case"

class TestNote < LinkedData::TestCase
  def self.before_suite
    self.new("before_suite").delete_ontologies_and_submissions
    @@ontology, @@cls = self.new("before_suite")._ontology_and_class
  end

  def self.after_suite
    self.new("after_suite").delete_ontologies_and_submissions
  end

  def _ontology_and_class
    count, acronyms, ontologies = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
    ontology = ontologies.first
    # TODO: Fix parsing issue (look at code in ontologies_api/test_case.rb)
    # cls = ontology.latest_submission.classes.first
    return ontology
  end

  def setup
    _variables
    _delete
    user = _user
    @note = LinkedData::Models::Note.new({
      noteId: @noteId,
      creator: user,
      relatedOntology: [@@ontology],
    })
    assert @note.valid?
    @note.save
  end

  def teardown
    _delete
  end

  def _variables
    @noteId = "Note_UUID_TESTING1"
    @note_user = "test_note_user"
  end

  def _user
    user = LinkedData::Models::User.new(
      username: @note_user,
      email: "note_user@example.org",
      password: "note_user_pass"
    )
    if user.exist?
      user = LinkedData::Models::User.find(@note_user).first
    else
      user.save
    end
    user
  end

  def _delete
    note = LinkedData::Models::Note.where(noteId: @noteId).first
    note.delete unless note.nil?
    user = LinkedData::Models::User.find(@note_user).first
    user.delete unless user.nil?
  end

  def test_valid_note
    note = LinkedData::Models::Note.new
    assert (not note.valid?)

    note.noteId = "TEST"
    note.creator = _user
    assert note.valid?
  end

  def test_note_lifecycle
    ontology = @@ontology

    n = LinkedData::Models::Note.new({
      noteId: "Note_UUID_TESTING2",
      creator: _user,
      relatedOntology: [ontology],
    })

    assert_equal false, n.exist?(reload=true)
    n.save
    assert_equal true, n.exist?(reload=true)
    n.delete
    assert_equal false, n.exist?(reload=true)
  end

  def test_note_class_proposal
    begin
      new_cls = LinkedData::Models::Notes::Details::ProposalNewClass.new
      new_cls.prefLabel = "New Label"
      new_cls.classId = "http://example.org/new/id"
      new_cls.save

      details = LinkedData::Models::Notes::Details::Base.new
      details.type = LinkedData::Models::Notes::Enums::Details.find("ProposalNewClass").first
      details.reasonForChange = "Need new term"
      details.content = new_cls
      details.save

      @note.details = details
      assert @note.valid?
    ensure
      details.delete unless details.nil?
      new_cls.delete unless new_cls.nil?
    end
  end

end
