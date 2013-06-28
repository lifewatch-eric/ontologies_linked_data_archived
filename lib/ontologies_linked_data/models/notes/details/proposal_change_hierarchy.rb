require_relative 'base'

module LinkedData
  module Models
    module Notes
      module Details
        class ProposalChangeHierarchy < LinkedData::Models::Notes::Details::Base
          model :proposal_change_hierarchy, name_with: lambda { |inst| uuid_uri_generator(inst) }
          attribute :newTarget, enforce: [:existence]
          attribute :oldTarget
          attribute :newRelationshipType, enforce: [:list]
        end
      end
    end
  end
end
