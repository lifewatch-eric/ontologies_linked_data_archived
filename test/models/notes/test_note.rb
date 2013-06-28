require_relative "../../test_case"

class TestNote < LinkedData::TestCase
  def self.before_suite
    self.new("before_suite").delete_ontologies_and_submissions
    @@ontology, @@cls = self.new("before_suite")._ontology_and_class
    @@note_user = "test_note_user"
    @@user = LinkedData::Models::User.new(
      username: @@note_user,
      email: "note_user@example.org",
      password: "note_user_pass"
    )
    @@user.save
  end

  def self.after_suite
    self.new("after_suite").delete_ontologies_and_submissions
    @@user.delete
  end

  def _ontology_and_class
    count, acronyms, ontologies = create_ontologies_and_submissions(ont_count: 1, submission_count: 1, process_submission: true)
    ontology = ontologies.first
    cls = LinkedData::Models::Class.where.include(:prefLabel).in(ontology.latest_submission).read_only.page(1, 1).first
    return ontology, cls
  end

  def setup
    _variables
    _delete
    @note = LinkedData::Models::Note.new({
      creator: @@user,
      relatedOntology: [@@ontology]
    })
    assert @note.valid?
    @note.save
  end

  def teardown
    _delete
  end

  def _variables
    @noteId = "Note_UUID_TESTING1"
  end

  def _delete
    note = LinkedData::Models::Note.where(noteId: @noteId).first
    note.delete unless note.nil?
    user = LinkedData::Models::User.find(@@note_user).first
    user.delete unless user.nil?
  end

  def test_valid_note
    note = LinkedData::Models::Note.new
    assert (not note.valid?)

    note.creator = @@user
    assert note.valid?
  end

  def test_note_lifecycle
    begin
      n = LinkedData::Models::Note.new({
        creator: @@user,
        relatedOntology: [@@ontology],
      })

      assert_equal false, n.exist?(reload=true)
      n.save
      assert_equal true, n.exist?(reload=true)
      n.delete
      assert_equal false, n.exist?(reload=true)
    ensure
      n.delete if !n.nil? && n.persistent?
    end
  end

  def test_note_class_proposal
    begin
      proposal = LinkedData::Models::Notes::Details::ProposalNewClass.new
      proposal.prefLabel = "New Label"
      proposal.classId = "http://example.org/new/id"
      proposal.save

      details = LinkedData::Models::Notes::Details::Base.new
      details.type = LinkedData::Models::Notes::Enums::Details.find("ProposalNewClass").first
      details.reasonForChange = "Need new term"
      details.content = proposal
      details.save

      @note.details = details
      assert @note.valid?
    ensure
      details.delete unless details.nil? && details.persistent?
      proposal.delete unless proposal.nil? && proposal.persistent?
    end
  end

  def test_note_change_hierarchy_proposal
    begin
      proposal = LinkedData::Models::Notes::Details::ProposalChangeHierarchy.new
      proposal.newTarget = "http://example.org/new/class"
      proposal.save

      details = LinkedData::Models::Notes::Details::Base.new
      details.type = LinkedData::Models::Notes::Enums::Details.find("ProposalChangeHierarchy").first
      details.reasonForChange = "Need new hierarchy"
      details.content = proposal
      details.save

      @note.details = details
      assert @note.valid?
    ensure
      details.delete unless details.nil? && details.persistent?
      proposal.delete unless proposal.nil? && proposal.persistent?
    end
  end

  def test_note_change_property
    begin
      proposal = LinkedData::Models::Notes::Details::ProposalChangeProperty.new
      proposal.propertyId = "http://example.org/property1"
      proposal.newValue = "My great value"
      proposal.save

      details = LinkedData::Models::Notes::Details::Base.new
      details.type = LinkedData::Models::Notes::Enums::Details.find("ProposalChangeProperty").first
      details.reasonForChange = "Need new property value"
      details.content = proposal
      details.save

      @note.details = details
      assert @note.valid?
    ensure
      details.delete unless details.nil? && details.persistent?
      proposal.delete unless proposal.nil? && proposal.persistent?
    end
  end

  def test_note_related_resource_delete
    note = LinkedData::Models::Note.new({
      creator: @@user,
      relatedOntology: [@@ontology],
    })

    proposal = LinkedData::Models::Notes::Details::ProposalChangeProperty.new
    proposal.propertyId = "http://example.org/property1"
    proposal.newValue = "My great value"
    proposal.save

    details = LinkedData::Models::Notes::Details::Base.new
    details.type = LinkedData::Models::Notes::Enums::Details.find("ProposalChangeProperty").first
    details.reasonForChange = "Need new property value"
    details.content = proposal
    details.save

    note.details = details
    note.save

    details_id = details.id
    note.delete
    retrieved_details = LinkedData::Models::Notes::Details::Base.find(details_id)
    assert_nil retrieved_details
  end

  def test_reply
    begin
      n = LinkedData::Models::Notes::Reply.new({
        creator: @@user,
        body: "This is my reply",
      })
      n.save

      @note.reply = [n]
      assert @note.valid?
    ensure
      n.delete if !n.nil? && n.persistent?
    end
  end


end
