require_relative '../enums/details'

module LinkedData
  module Models
    module Notes
      module Details
        class Base < LinkedData::Models::Base
          attribute :type, :instance_of => {:with => LinkedData::Models::Notes::Enums::Details}, :single_value => true, :not_nil => true
          attribute :contactInfo
          attribute :reasonForChange, :not_nil => true, :single_value => true
          attribute :content, :instance_of => {:with => LinkedData::Models::Notes::Details::Base}, :not_nil => true, :single_value => true

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