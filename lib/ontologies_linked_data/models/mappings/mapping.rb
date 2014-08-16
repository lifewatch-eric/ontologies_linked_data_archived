
module LinkedData
  module Models
    class Mapping
      include LinkedData::Hypermedia::Resource
      embed :classes

      def initialize(classes, type, process=nil)
        @classes = classes
        @process = process
        @type = type
      end
      def classes
        return @classes
      end
      def process
        return @process
      end
      def type
        return @type
      end
    end

    class RestBackupMapping < LinkedData::Models::Base
      model :rest_backup_mapping, name_with: :uuid
      attribute :uuid, enforce: [:existence, :unique]
      attribute :class_urns, enforce: [:uri, :existence, :list]
      attribute :process, enforce: [:existence, :mapping_process]
    end

    class MappingProcess < LinkedData::Models::Base
          model :mapping_process, name_with: :name
          attribute :name, enforce: [:unique, :existence]
          attribute :creator, enforce: [:existence, :user]

          #only manual mappings
          attribute :source
          attribute :relation, enforce: [:uri]
          attribute :source_contact_info
          attribute :source_name
          attribute :comment
          attribute :date, enforce: [:date_time]

          # Hypermedia settings
          embedded true
    end
  end
end
