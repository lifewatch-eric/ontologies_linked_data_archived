require_relative '../enums/details'

module LinkedData
  module Models
    module Notes
      module Details
        class Base < LinkedData::Models::Base
          model :base, name_with: lambda { |s| uuid_uri_generator(inst) } 
          attribute :type, enforce: [:details, :existence]
          attribute :contactInfo, enforce: [:list]
          attribute :reasonForChange, enforce: [:existence]
          attribute :content, enforce: [:existence, :base]

          embed_values :type => [:type]

          def initialize(attributes = {})
            if self.class != LinkedData::Models::Notes::Details::Base
              super(attributes)
              return self
            else
              super(attributes)
            end
          end
        end
      end
    end
  end
end
