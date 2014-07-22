
module LinkedData
  module Models
    class TermMapping
      def initialize(classId,submissionId)
        @classId = classId
        @submissionId = submissionId
      end
      def classId
        return @classId
      end
      def submissionId
        return @submissionId
      end
    end

    class Mapping
      def initialize(terms, type, process=nil)
        @terms = terms
        @process = process
        @type = type
      end
      def terms
        return @terms
      end
      def process
        return @process
      end
      def type
        return @type
      end
    end
  end
end
