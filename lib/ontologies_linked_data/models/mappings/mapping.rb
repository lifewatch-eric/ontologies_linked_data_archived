
module LinkedData
  module Models
    class Mapping
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
  end
end
