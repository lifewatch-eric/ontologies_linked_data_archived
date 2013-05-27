require_relative '../enums/details'

module LinkedData
  module Models
    module Notes
      module Details
        class Base < LinkedData::Models::Base
          model :base, name_with: lambda { |inst| uuid_uri_generator(inst) }
          attribute :type, enforce: [LinkedData::Models::Notes::Enums::Details, :existence]
          attribute :contactInfo, enforce: [:list]
          attribute :reasonForChange, enforce: [:existence]
          attribute :content, enforce: [:existence, LinkedData::Models::Notes::Details::Base]

          embed_values :type => [:type]
        end
      end
    end
  end
end
