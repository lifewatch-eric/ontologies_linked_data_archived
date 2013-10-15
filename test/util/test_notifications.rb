require_relative "../test_case"
require "email_spec"
require "logger"

class TestNotifications < LinkedData::TestCase
  include EmailSpec::Helpers

  def self.before_suite
    @@notifications_enabled = LinkedData.settings.enable_notifications
    @@disable_override = LinkedData.settings.email_disable_override
    LinkedData.settings.email_disable_override = true
    LinkedData.settings.enable_notifications = true
    @@ont = LinkedData::SampleData::Ontology.create_ontologies_and_submissions(ont_count: 1, submission_count: 1)[2].first
    @@ont.bring_remaining
    @@user = @@ont.administeredBy.first
    @@subscription = self.new("before_suite")._subscription(@@ont)
    @@user.bring_remaining
    @@user.subscription = [@@subscription]
    @@user.save
  end

  def self.after_suite
    LinkedData.settings.enable_notifications = @@notifications_enabled
    LinkedData.settings.email_disable_override = @@disable_override
    @@ont.delete if defined?(@@ont)
    @@subscription.delete if defined?(@@subscription)
    @@user.delete if defined?(@@user)
  end

  def setup
    LinkedData.settings.email_disable_override = true
  end

  def _subscription(ont)
    subscription = LinkedData::Models::Users::Subscription.new
    subscription.ontology = ont
    subscription.notification_type = LinkedData::Models::Users::NotificationType.find("ALL").first
    subscription.save
  end

  def test_send_notification
    recipients = ["test@example.org"]
    subject = "Test subject"
    body = "My test body"

    # Email recipient address will be overridden
    LinkedData.settings.email_disable_override = false
    LinkedData::Utils::Notifications.notify(recipients: recipients)
    assert_equal [LinkedData.settings.email_override], last_email_sent.to

    # Disable override
    LinkedData.settings.email_disable_override = true
    LinkedData::Utils::Notifications.notify({
      recipients: recipients,
      subject: subject,
      body: body
    })
    assert_equal recipients, last_email_sent.to
    assert_equal [LinkedData.settings.email_sender], last_email_sent.from
    assert_equal last_email_sent.body.raw_source, body
    assert_equal last_email_sent.subject, subject
  end

  def test_new_note_notification
    begin
      subject = "Test note subject"
      body = "Test note body"
      note = LinkedData::Models::Note.new
      note.creator = @@user
      note.subject = subject
      note.body = body
      note.relatedOntology = [@@ont]
      note.save

      assert last_email_sent.subject.include?("[BioPortal Notes]")
      assert_equal [@@user.email], last_email_sent.to
    ensure
      note.delete if note
    end
  end

  def test_processing_complete_notification
    begin
      options = {ont_count: 1, submission_count: 1, acronym: "NOTIFY"}
      ont = LinkedData::SampleData::Ontology.create_ontologies_and_submissions(options)[2].first
      subscription = _subscription(ont)
      @@user.subscription = @@user.subscription.dup << subscription
      @@user.save
      ont.latest_submission(status: :any).process_submission(Logger.new($stdout))
      assert last_email_sent.subject.include?("Parsing Success")
      assert_equal [@@user.email], last_email_sent.to
    ensure
      ont.delete if ont
      subscription.delete if subscription
    end
  end
end
