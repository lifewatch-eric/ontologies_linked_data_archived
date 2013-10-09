require "test/unit"
require_relative "../../lib/ontologies_linked_data"

class TestLinkedDataConfig < MiniTest::Unit::TestCase

  def setup
    Goo.class_variable_set("@@sparql_backends", {})
    LinkedData.instance_variable_set("@settings_run", false)
    LinkedData.settings.goo_host = nil
    LinkedData.settings.goo_port = nil
  end

  def teardown
    Goo.class_variable_set("@@sparql_backends", {})
    LinkedData.instance_variable_set("@settings_run", false)
  end

  def test_default_config
    puts
    LinkedData.config()
    assert_equal('localhost', LinkedData.settings.goo_host, msg="goo_host != localhost")
    assert_equal(9000, LinkedData.settings.goo_port, msg="goo_port != 9000")
    assert_equal(false, Goo.sparql_data_client.nil?, msg='sparql_data_client is nil')
    assert_equal(false, Goo.sparql_update_client.nil?, msg='sparql_update_client is nil')
    assert_equal(false, Goo.sparql_query_client.nil?, msg='sparql_query_client is nil')
  end

  def test_custom_config
    puts
    test_host = 'test_host'
    test_port = 1111
    # Re-configure
    LinkedData.config do |config, overide_connect_goo|
      overide_connect_goo = true # Prevent goo connection
      config.goo_port = test_port
      config.goo_host = test_host
    end
    assert_equal(test_host, LinkedData.settings.goo_host, msg="goo_host != test_host")
    assert_equal(test_port, LinkedData.settings.goo_port, msg="goo_port != test_port")
    assert_equal(false, Goo.sparql_data_client.nil?, msg='sparql_data_client is nil')
    assert_equal(false, Goo.sparql_update_client.nil?, msg='sparql_update_client is nil')
    assert_equal(false, Goo.sparql_query_client.nil?, msg='sparql_query_client is nil')
  end

  def test_config_file
    puts
    load(File.expand_path("../../../config/config.rb", __FILE__))
  end

end
