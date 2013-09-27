require 'pony'

module LinkedData::Utils
  class Notifications

    def self.notify(options = {})
      headers = { 'Content-Type' => 'text/html' }
      sender    = options[:sender] || LinkedData.settings.email_sender
      recipient = options[:recipient]

      # By default we override all recipients to avoid
      # sending emails from testing environments.
      # Set `email_disable_override` in production
      # to send to the actual user.
      unless LinkedData.settings.email_disable_override
        headers['Overridden-Sender'] = recipient
        recipient = LinkedData.settings.email_override
      end

      Pony.mail({
        to: recipient,
        from: sender,
        subject: options[:subject],
        body: options[:body],
        headers: headers,
        via: :smtp,
        via_options: mail_options
      })
    end

    def self.new_note(note)
      note.bring_remaining
      note.creator.bring(:username) if note.creator.bring?(:username)
      note.relatedOntology.each {|o| o.bring(:name) if o.bring?(:name); o.bring(:subscriptions) if o.bring?(:subscriptions)}
      subject = "[BioPortal Notes] #{note.subject}"
      body = NEW_NOTE.gsub("%username%", note.creator.username)
                     .gsub("%ontologies%", note.relatedOntology.map {|o| o.name}.join(", "))
                     .gsub("%note_url%", LinkedData::Hypermedia.generate_links(note)["ui"])
                     .gsub("%note_subject%", note.subject || "")
                     .gsub("%note_body%", note.body || "")


      emails = []
      note.relatedOntology.each do |ont|
        ont.subscriptions.each do |subscription|
          subscription.bring(:notification_type) if subscription.bring?(:notification_type)
          subscription.notification_type.bring(:type) if subscription.notification_type.bring?(:notification_type)
          next unless subscription.notification_type.type.eql?("NOTES")
          subscription.bring(:user) if subscription.bring?(:user)
          subscription.user.each do |user|
            user.bring(:email) if user.bring?(:email)
            emails << notify(recipient: user.email, subject: subject, body: body)
          end
        end
      end

      emails
    end

    private

    def self.mail_options
      options = {
        address: LinkedData.settings.smtp_host,
        port:    LinkedData.settings.smtp_port,
        domain:  LinkedData.settings.smtp_domain # the HELO domain provided by the client to the server
      }

      if LinkedData.settings.smtp_auth_type && LinkedData.settings.smtp_auth_type != :none
        options.merge({
          user_name:      LinkedData.settings.smtp_user,
          password:       LinkedData.settings.smtp_password,
          authentication: LinkedData.settings.smtp_auth_type
        })
      end

      return options
    end

NEW_NOTE = <<EOS
A new note was added to %ontologies% by <b>%username%</b>.<br/><br/>

----------------------------------------------------------------------------------<br/>
<b>Subject:</b> %note_subject%<br/>

%note_body%
----------------------------------------------------------------------------------<br/><br/>

You can respond by visiting: <a href="%note_url%">NCBO BioPortal</a>.<br/><br/>
EOS

  end
end