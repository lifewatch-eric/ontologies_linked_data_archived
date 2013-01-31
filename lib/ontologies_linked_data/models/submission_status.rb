module LinkedData
  module Models
    class SubmissionStatus < LinkedData::Models::Base
      model :submission_status
      attribute :code, :unique => true
      attribute :submissions,
              :inverse_of => { :with => :ontology_submission ,
              :attribute => :submissionStatus }

      def self.init(values = ["UPLOADED", "RDF", "LABELS", "INDEXED", "READY", "ERROR_LABELS","ERROR_RDF", "ERROR_INDEX"])
        values.each do |code|
          of =  LinkedData::Models::SubmissionStatus.new( { :code => code } )
          if not of.exist?
            of.save
          end
        end
      end

      def parsed?
        #TODO eventually this has to check for READY.
        self.load unless self.loaded?
        return (self.code == "RDF")
      end
    end
  end
end

