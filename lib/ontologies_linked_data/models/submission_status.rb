module LinkedData
  module Models
    class SubmissionStatus < LinkedData::Models::Base
      VALUES = [
        "UPLOADED", "ERROR_UPLOADED",
        "RDF", "ERROR_RDF",
        "RDF_LABELS", "ERROR_RDF_LABELS",
        "INDEXED", "ERROR_INDEXED",
        "METRICS",  "ERROR_METRICS",
        "ANNOTATOR", "ERROR_ANNOTATOR",
        "ARCHIVED", "ERROR_ARCHIVED"
      ]

      USER_READABLE = {
        "RDF"             => "Parsed successfully",
        "RDF_ERROR"       => "Error parsing",
        "INDEXED"         => "Indexed for search",
        "ERROR_INDEXED"   => "Error indexing for search",
        "METRICS"         => "Class metrics calculated",
        "ERROR_METRICS"   => "Error calculating class metrics",
        "ANNOTATOR"       => "Processed for use in Annotator",
        "ERROR_ANNOTATOR" => "Error processing for use in Annotator"
      }

      USER_IGNORE = [
        "UPLOADED", "ERROR_UPLOADED",
        "RDF_LABELS", "ERROR_RDF_LABELS",
      ]

      model :submission_status, name_with: :code
      attribute :code, enforce: [:existence, :unique]
      attribute :submissions,
              :inverse => { :on => :ontology_submission,
              :attribute => :submissionStatus }
      enum VALUES

      def error?
        code = get_code_from_id()
        return code.start_with?("ERROR_")
      end

      def get_error_status
        return self if error?
        code = get_code_from_id()
        return SubmissionStatus.find("ERROR_#{code}").include(:code).first
      end

      def get_non_error_status
        return self unless error?
        code = get_code_from_id()
        code.sub!("ERROR_", "")
        return SubmissionStatus.find(code).include(:code).first
      end

      def get_code_from_id
        return self.id.to_s.split("/")[-1]
      end

      def self.readable_statuses(statuses)
        statuses = statuses.map {|s| s.code}
        statuses = statuses - USER_IGNORE
        statuses.sort! {|a,b| VALUES.index(a) <=> VALUES.index(b)}
        statuses.map {|s| USER_READABLE[s] || s.capitalize}
      end

      def self.status_ready?(status)
        status = status.is_a?(Array) ? status : [status]
        # Using http://ruby-doc.org/core-2.0/Enumerable.html#method-i-all-3F
        all_typed_correctly = status.all? {|s| s.is_a?(LinkedData::Models::SubmissionStatus)}
        raise ArgumentError, "One or more statuses were not SubmissionStatus objects" unless all_typed_correctly

        ready_status_codes = self.get_ready_status
        status_codes = self.get_status_codes(status)
        return (ready_status_codes - status_codes).size == 0
      end

      def self.get_status_codes(status)
        return status.map { |s| s.get_code_from_id() }
      end

      def self.get_ready_status
        return [
            #"UPLOADED",
            "RDF",
            #"RDF_LABELS",
            #"INDEXED",
            #"METRICS",
            #"ANNOTATOR"
        ]
      end
    end
  end
end

