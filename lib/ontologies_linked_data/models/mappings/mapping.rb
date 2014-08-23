
module LinkedData
  module Models
    class Mapping
      include LinkedData::Hypermedia::Resource
      embed :classes, :process

      def initialize(classes, type, process=nil, id=nil)
        @classes = classes
        @process = process
        @type = type
        @id = id
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

    #only manual mappings
    class MappingProcess < LinkedData::Models::Base
          model :mapping_process, 
                :name_with => lambda { |s| process_id_generator(s) }
          attribute :name, enforce: [:existence]
          attribute :creator, enforce: [:existence, :user]

          attribute :source
          attribute :relation, enforce: [:uri]
          attribute :source_contact_info
          attribute :source_name
          attribute :comment
          attribute :date, enforce: [:date_time]

          embedded true

          def self.process_id_generator(inst)
            if inst.date
              #rest mapping
              return RDF::IRI.new(
        "#{(self.namespace)}mapping_processes/#{CGI.escape(inst.name.to_s)}" +
        "-#{CGI.escape(inst.creator.username)}" +
        "-#{UUID.new.generate}")
            end
            return RDF::IRI.new(
              "#{(self.namespace)}mapping_processes/#{CGI.escape(inst.name.to_s)}-#{CGI.escape(inst.creator.username)}")
          end
    end
  end
end
