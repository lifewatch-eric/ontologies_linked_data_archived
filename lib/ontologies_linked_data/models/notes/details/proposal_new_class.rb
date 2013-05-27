require_relative 'base'

module LinkedData
  module Models
    module Notes
      module Details
        class ProposalNewClass < LinkedData::Models::Notes::Details::Base
          model :proposal_new_class, name_with: lambda { |inst| uuid_uri_generator(inst) }
          attribute :classId, enforce: [:existence]
          attribute :prefLabel, enforce: [:existence]
          attribute :synonyms, enforce: [:list]
          attribute :definitions, enforce: [:list]
          attribute :parent
        end
      end
    end
  end
end
