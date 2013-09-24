require 'pony'

module LinkedData::Utils
  class Notifications

    def self.notify(options = {})
      headers = { 'Content-Type' => 'text/html' }
      sender    = options[:sender] || LinkedData.settings.email_sender
      recipient = options[:recipient]

      if LinkedData.settings.email_disable_override
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
  end
end