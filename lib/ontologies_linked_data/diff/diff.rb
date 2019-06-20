module LinkedData
  module Diff
    class <<self
      attr_accessor :logger
    end
    class DiffException < Exception
    end
    class MkdirException < DiffException
    end
    class BubastisDiffException < DiffException
    end
  end
end
require_relative "bubastis_diff"
