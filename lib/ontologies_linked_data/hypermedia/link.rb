module LinkedData
  module Hypermedia
    class Link
      attr_accessor :path, :type, :type_uri
      def initialize(type, path)
        @path = path; @type = type
      end
    end
  end
end

