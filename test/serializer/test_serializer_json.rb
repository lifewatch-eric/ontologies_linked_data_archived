require "test/unit"
require "json"
require_relative "../../lib/ontologies_linked_data"

class Car < LinkedData::Models::Base
  attribute :model, :unique => true
end

class House < LinkedData::Models::Base
  attribute :location, :unique => true
end

class Person < LinkedData::Models::Base
  attribute :name, :unique => true
  attribute :age
  attribute :height
  attribute :carOwned, :instance_of => {:with => :car}
  attribute :houseOwned, :instance_of => {:with => House}
end

class TestSerializerOutput < Test::Unit::TestCase

  def setup
    @attrs = {name: "Simon", age: 21}
    teardown
    @person = Person.new(@attrs)
    @person.save
  end

  def teardown
    person = Person.where(@attrs).first rescue nil
    person.delete unless person.nil?
  end

  def test_person_to_json
    json = LinkedData::Serializers.serialize(@person, :json)
    reference = JSON.parse(json)
    assert reference.key?("name")
    assert reference.key?("age")
    assert reference.key?("@type")
    assert reference.key?("@id")
    assert reference.key?("@context")
    assert reference["@context"].key?("@vocab")
    assert reference["@context"].key?("carOwned")
    assert reference["@context"].key?("houseOwned")
  end

  def test_hash_to_json
    hash = {test: "value", name: "testing"}
    json = LinkedData::Serializers.serialize(hash, :json)
    reference = JSON.parse(json)
    assert reference.key?("test")
    assert reference.key?("name")
  end

end