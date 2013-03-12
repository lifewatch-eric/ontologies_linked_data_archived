module LinkedData
  module Hypermedia
    class Link
      attr_accessor :path, :type, :type_uri
      def initialize(type, path, type_uri = nil)
        @path = path; @type = type; @type_uri = type_uri
      end
    end
  end
end

