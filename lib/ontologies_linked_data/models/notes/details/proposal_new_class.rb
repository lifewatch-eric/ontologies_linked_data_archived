require_relative 'base'

module LinkedData
  module Models
    module Notes
      module Details
        class ProposalNewClass < LinkedData::Models::Notes::Details::Base
          attribute :classId, :not_nil => true, :single_value => true
          attribute :prefLabel, :not_nil => true, :single_value => true
          attribute :synonyms
          attribute :definitions
          attribute :parent
        end
      end
    end
  end
end