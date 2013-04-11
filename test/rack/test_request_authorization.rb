require "test/unit"
require "rack/test"
require "json"
require_relative "../../lib/ontologies_linked_data"
require_relative "../../config/config.rb"


class TestRackAuthorization < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    eval "Rack::Builder.new {( " + File.read(File.dirname(__FILE__) + '/authorization.ru') + "\n )}"
  end

  def setup
    _variables
    _delete_user
    user = _create_user
    @apikey = user.apikey
  end

  def teardown
    _delete_user
  end

  def _variables
    @username = "test_username"
  end

  def _create_user
    user = LinkedData::Models::User.new({
      username: @username,
      password: "test_password",
      email: "test_email@example.org"
    })
    user.save unless user.exist?
  end

  def _delete_user
    user = LinkedData::Models::User.find(@username)
    user.delete unless user.nil?
  end

  def test_authorize
    get "/", {}, {"Authorization" => 'apikey token="'+@apikey+'"'}
    assert last_response.status != 403
    get "/", {}, {"Authorization" => "apikey token=#{@apikey}"}
    assert last_response.status != 403
    get "/?apikey=#{@apikey}"
    assert last_response.status != 403
  end

end