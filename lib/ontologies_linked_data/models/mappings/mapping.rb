
module LinkedData
  module Models
    class TermMapping
      def initialize(classId,ontologyId)
        @classId = classId
        @ontologyId = ontologyId
      end
    end

    class Mapping
      def initialize(termMappings, date, process=nil)
        @termMappings = termMappings
        @date = date
        @process = process
      end
    end
  end
end
