require "test/unit"
require "json"
require_relative "../../lib/ontologies_linked_data"

class TestSerializerOutput < Test::Unit::TestCase
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

  def setup
    @attrs = {name: "Simon", age: 21}
    @car_attrs = {model: "Firebird"}
    @house_attrs = {location: "San Martin"}
    teardown
    @car = Car.new(@car_attrs)
    @car.save
    @house = House.new(@house_attrs)
    @house.save
    @person = Person.new(@attrs)
    @person.carOwned = @car
    @person.houseOwned = @house
    @person.save
  end

  def teardown
    house = House.where(@house_attrs).first rescue nil
    house.delete unless house.nil?
    car = Car.where(@car_attrs).first rescue nil
    car.delete unless car.nil?
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