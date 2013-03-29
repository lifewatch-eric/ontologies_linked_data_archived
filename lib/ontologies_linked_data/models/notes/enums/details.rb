module LinkedData
  module Models
    module Notes
      module Enums
        class Details < LinkedData::Models::Base
          DEFAULT = "ProposalNewClass"

          # Value stored on class so we only initialize once
          class << self
            attr_accessor :initialized
          end

          attribute :type, :unique => true, :single_value => true, :not_nil => true

          def self.init(values = ["ProposalNewClass", "ProposalChangeHierarchy", "ProposalChangeProperty"])
            return false if self.initialized
            values.each do |type|
              detail_type = LinkedData::Models::Notes::Enums::Details.new(:type => type)
              detail_type.save unless detail_type.exist?
            end
            self.initialized = true
          end

          def self.default
            LinkedData::Models::Notes::Enums::Details.init
            self.find(DEFAULT)
          end

          def self.find(param, store_name=nil)
            LinkedData::Models::Notes::Enums::Details.init
            super(param, store_name)
          end
        end
      end
    end
  end
end