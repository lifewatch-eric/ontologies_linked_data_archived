module LinkedData
  module Models
    module Notes
      class Details < LinkedData::Models::Base
        DEFAULT = "ProposalNewClass"
        VALUES = ["ProposalNewClass", "ProposalChangeHierarchy", "ProposalChangeProperty"]

        model :details, name_with: :type
        attribute :type, enforce: [:existence, :unique]
        enum VALUES
      end
    end
  end
end
