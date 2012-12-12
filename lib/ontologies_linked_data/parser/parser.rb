module LinkedData
  module Parser
    class ParserException < Exception
    end
    class MkdirException < ParserException
    end
  end
end
require_relative "owlapi"
