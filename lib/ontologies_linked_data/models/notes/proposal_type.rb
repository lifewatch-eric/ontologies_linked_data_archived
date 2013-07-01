module LinkedData
  module Models
    module Notes
      class ProposalType < LinkedData::Models::Base
        DEFAULT = "ProposalNewClass"
        VALUES = ["ProposalNewClass", "ProposalChangeHierarchy", "ProposalChangeProperty"]

        model :details, name_with: :type
        attribute :type, enforce: [:existence, :unique]
        enum VALUES

        embedded true
      end
    end
  end
end
