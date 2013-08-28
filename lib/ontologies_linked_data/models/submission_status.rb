module LinkedData
  module Models
    class SubmissionStatus < LinkedData::Models::Base
      VALUES = ["UPLOADED", "RDF", "LABELS", "INDEXED", "READY", "ERROR_LABELS", "ERROR_RDF", "ERROR_INDEX", "ARCHIVED"]
      model :submission_status, name_with: :code
      attribute :code, enforce: [:existence, :unique]
      attribute :submissions,
              :inverse => { :on => :ontology_submission ,
              :attribute => :submissionStatus }
      enum VALUES

      def self.parsed_code
        "RDF"
      end

      def parsed?
        #TODO eventually this has to check for READY.
        return (self.id.to_s.end_with?(self.class.parsed_code))
      end
    end
  end
end

