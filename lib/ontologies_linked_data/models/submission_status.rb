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
      @ready_status = nil

      model :submission_status, name_with: :code
      attribute :code, enforce: [:existence, :unique]
      attribute :submissions,
              :inverse => { :on => :ontology_submission,
              :attribute => :submissionStatus }
      enum VALUES

      def error?
        self.bring(:code) if self.bring?(:code)
        return self.code.start_with?("ERROR_")
      end

      def get_error_status
        return self if error?
        return SubmissionStatus.find("ERROR_#{self.code}").include(:code).first
      end

      def get_non_error_status
        return self unless error?
        code = self.code.sub("ERROR_", "")
        return SubmissionStatus.find(code).include(:code).first
      end

      def self.status_ready?(status)
        status = status.is_a?(Array) ? status : [status]
        # Using http://ruby-doc.org/core-2.0/Enumerable.html#method-i-all-3F
        all_typed_correctly = status.all? {|s| s.is_a?(LinkedData::Models::SubmissionStatus)}
        raise ArgumentError, "One or more statuses were not SubmissionStatus objects" unless all_typed_correctly

        ready_status_codes = self.get_ready_status.map {|s| s.code}
        status_codes = status.map { |s|
          s.bring(:code) if s.bring?(:code)
          s.code
        }
        return (ready_status_codes - status_codes).size == 0
      end

      def self.get_ready_status
        @ready_status ||= [
            SubmissionStatus.find("UPLOADED").include(:code).first,
            SubmissionStatus.find("RDF").include(:code).first,
            SubmissionStatus.find("RDF_LABELS").include(:code).first,
            SubmissionStatus.find("INDEXED").include(:code).first,
            SubmissionStatus.find("METRICS").include(:code).first
        ]
        return @ready_status
      end
    end
  end
end

