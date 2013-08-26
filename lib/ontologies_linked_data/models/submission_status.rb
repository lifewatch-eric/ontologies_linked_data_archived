module LinkedData
  module Models
    class SubmissionStatus < LinkedData::Models::Base
      VALUES = [
        "UPLOADED", "ERROR_UPLOADED",
        "RDF", "ERROR_RDF",
        "RDF_LABELS", "ERROR_RDF_LABELS",
        "INDEXED", "ERROR_INDEXED",
        "METRICS",  "ERROR_METRICS",
        "ARCHIVED"
      ]
      @ready_status = [
          SubmissionStatus.find("UPLOADED").first,
          SubmissionStatus.find("RDF").first,
          SubmissionStatus.find("RDF_LABELS").first,
          SubmissionStatus.find("INDEXED").first,
          SubmissionStatus.find("METRICS").first
      ]

      model :submission_status, name_with: :code
      attribute :code, enforce: [:existence, :unique]
      attribute :submissions,
              :inverse => { :on => :ontology_submission,
              :attribute => :submissionStatus }
      enum VALUES

      def get_ready_status
        return @ready_status
      end

      def is_error?
        return self.code.start_with?("ERROR_")
      end

      def get_error_status
        if is_error?
          return self
        end

        return SubmissionStatus.find("ERROR_#{self.code}").first
      end

      def self.status_ready?(statusArr)
        status = status.is_a?(Array) ? status : [status]

        # Using http://ruby-doc.org/core-2.0/Enumerable.html#method-i-all-3F
        all_typed_correctly = status.all? {|s| s.is_a?(LinkedData::Models::SubmissionStatus)}
        raise ArgumentException, "One or more statuses were not SubmissionStatus objects" unless all_typed_correctly

        return (@ready_status - status).size == 0
      end
    end
  end
end

