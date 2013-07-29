require_relative "../test_case"

class TestAccessControl < LinkedData::TestCase

  def self.before_suite
    self.new("before_suite").delete_ontologies_and_submissions

    @@usernames = ["user1", "user2", "user3", "admin"]
    _delete_users
    @@usernames.each do |username|
      user = LinkedData::Models::User.new(
        username: username,
        email: "#{username}@example.org",
        password: "note_user_pass"
      )
      user.save
      user.bring_remaining
      self.class_variable_set(:"@@#{username}", user)
    end

    @@admin.role = [LinkedData::Models::Users::Role.find(LinkedData::Models::Users::Role::ADMIN).first]
    @@admin.save

    onts = LinkedData::SampleData::Ontology.sample_owl_ontologies

    @@restricted_ont = onts.shift
    @@restricted_ont.bring(:submissions)
    @@restricted_ont.bring_remaining
    @@restricted_ont.viewingRestriction = "private"
    @@restricted_ont.acl = [@@user2, @@user3]
    @@restricted_ont.administeredBy = [@@user1]
    @@restricted_ont.save
    @@restricted_user = @@restricted_ont.administeredBy.first
    @@restricted_user.bring_remaining
    @@restricted_sub = @@restricted_ont.latest_submission.bring(*LinkedData::Models::OntologySubmission.goo_attrs_to_load)

    @@ont = onts.shift
    @@ont.bring(:submissions)
    @@ont.bring_remaining
    @@user = @@ont.administeredBy.first
    @@user.bring_remaining
    @@sub = @@ont.latest_submission.bring(*LinkedData::Models::OntologySubmission.goo_attrs_to_load)

    @@note = LinkedData::Models::Note.new({
      creator: @@user,
      subject: "Test subject",
      body: "Test body for note",
      relatedOntology: [@@ont]
    })
    @@note.save

    @@old_security_setting = LinkedData.settings.enable_security
    LinkedData.settings.enable_security = true
  end

  def self.after_suite
    LinkedData.settings.enable_security = @@old_security_setting if class_variable_defined?("@@old_security_setting")
    _delete_users
    self.new("after_suite").delete_ontologies_and_submissions
    @@note.delete if class_variable_defined?("@@note")
  end

  def self._delete_users
    @@usernames.each {|u| user = LinkedData::Models::User.find(u).first; user.delete unless user.nil?}
  end

  def test_basic_restriction
    assert @@ont.readable?(@@user)
    assert @@ont.readable?(@@user1)
    assert @@restricted_ont.read_restricted?
    assert @@restricted_ont.readable?(@@restricted_user)
    assert @@restricted_ont.readable?(@@user2)
    assert @@restricted_ont.readable?(@@user3)
    refute @@restricted_ont.readable?(@@user)
  end

  def test_unrestricted_admin
    assert @@ont.writable?(@@admin)
    assert @@sub.writable?(@@admin)
    assert @@restricted_ont.writable?(@@admin)
    assert @@restricted_sub.writable?(@@admin)
    assert @@note.writable?(@@admin)
  end

  def test_write_owner
    assert @@user.writable?(@@user)
    refute @@user.writable?(@@user1)
    assert @@note.writable?(@@user)
    refute @@note.writable?(@@user1)
  end

  def test_read_restricted_based_on
    @@sub.ontology.bring(*LinkedData::Models::Ontology.goo_attrs_to_load)
    refute @@sub.read_restricted?
    assert @@sub.readable?(@@user)
    assert @@sub.readable?(@@user1)
    assert @@sub.readable?(@@restricted_user)
    @@restricted_sub.ontology.bring(*LinkedData::Models::Ontology.goo_attrs_to_load)
    assert @@restricted_sub.read_restricted?
    assert @@restricted_sub.readable?(@@restricted_user)
    assert @@restricted_sub.readable?(@@user2)
    assert @@restricted_sub.readable?(@@user3)
    refute @@restricted_sub.readable?(@@user)
    assert @@restricted_sub.read_restricted?
    assert @@restricted_sub.readable?(@@restricted_user)
    assert @@restricted_sub.readable?(@@user2)
    assert @@restricted_sub.readable?(@@user3)
    refute @@restricted_sub.readable?(@@user)
  end

  def test_write_restricted
    assert @@restricted_ont.writable?(@@restricted_user)
    refute @@restricted_ont.writable?(@@user2)
    refute @@restricted_ont.writable?(@@user3)
    refute @@restricted_ont.writable?(@@user)
  end
end
