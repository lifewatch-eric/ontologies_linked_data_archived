require_relative "../config/default.rb"
require_relative "../lib/ontologies_linked_data"
require "test/unit"

LinkedData.config

module LinkedData
  class TestCase < Test::Unit::TestCase
  end
end