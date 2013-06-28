require_relative '../enums/details'

module LinkedData
  module Models
    module Notes
      class Proposal < LinkedData::Models::Base
        model :base, name_with: lambda { |inst| uuid_uri_generator(inst) }
        attribute :type, enforce: [LinkedData::Models::Notes::Enums::Details, :existence]
        attribute :contactInfo
        attribute :reasonForChange, enforce: [:existence]

        # ProposalChangeHierarchy
        attribute :newTarget, enforce: [lambda {|inst, attr| existence(instance, attribute, "ProposalChangeHierarchy")}]
        attribute :oldTarget
        attribute :newRelationshipType, enforce: [:list]

        # ProposalChangeProperty
        attribute :propertyId, enforce: [lambda {|inst, attr| existence(instance, attribute, "ProposalChangeProperty")}]
        attribute :newValue, enforce: [lambda {|inst, attr| existence(instance, attribute, "ProposalChangeProperty")}]
        attribute :oldValue

        # ProposalNewClass
        attribute :classId
        attribute :label, enforce: [lambda {|inst, attr| existence(instance, attribute, "ProposalNewClass")}]
        attribute :synonym, enforce: [:list]
        attribute :definition, enforce: [:list]
        attribute :parent

        embed :content
        embed_values :type => [:type]
        embedded true

        def self.existence(instance, attribute, type)
          if instance.type.eql?(type)
            return :existence, "`#{attr}` value cannot be nil" if instance.send(attribute).nil?
          end
          return nil, nil
        end
      end
    end
  end
end
