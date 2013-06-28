require_relative 'base'

module LinkedData
  module Models
    module Notes
      module Details
        class ProposalChangeProperty < LinkedData::Models::Notes::Details::Base
          model :proposal_change_property, name_with: lambda { |inst| uuid_uri_generator(inst) }
          attribute :propertyId, enforce: [:existence]
          attribute :newValue, enforce: [:existence]
          attribute :oldValue
        end
      end
    end
  end
end
