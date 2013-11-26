require "ostruct"
require_relative "../test_case"
require_relative "../../lib/ontologies_linked_data"

class TestLinkedDataConfig < LinkedData::TestCase

  def self.before_suite
    @@sparql_holder = Goo.class_variable_get("@@sparql_backends")
    @@settings_holder = LinkedData.settings
  end

  def self.after_suite
    begin
      Goo.class_variable_set("@@sparql_backends", @@sparql_holder)
      LinkedData.instance_variable_set("@settings_run", true)
    ensure
      LinkedData.instance_variable_set("@settings", @@settings_holder)
    end
  end

  def teardown
    Goo.class_variable_set("@@sparql_backends", {})
    LinkedData.instance_variable_set("@settings_run", false)
    load(File.expand_path("../../../config/config.rb", __FILE__))
  end

  def test_default_config
    # Override safety check
    Goo.class_variable_set("@@sparql_backends", {})
    LinkedData.instance_variable_set("@settings_run", false)
    LinkedData.instance_variable_set("@settings", OpenStruct.new)
    LinkedData.config()

    assert_equal('localhost', LinkedData.settings.goo_host, msg="goo_host != localhost")
    assert_equal(false, Goo.sparql_data_client.nil?, msg='sparql_data_client is nil')
    assert_equal(false, Goo.sparql_update_client.nil?, msg='sparql_update_client is nil')
    assert_equal(false, Goo.sparql_query_client.nil?, msg='sparql_query_client is nil')
  end

  def test_custom_config
    test_port = 1111
    test_host = "test_host"

    # Override safety check
    LinkedData.instance_variable_set("@settings", OpenStruct.new)
    LinkedData.instance_variable_set("@settings_run", false)

    # Re-configure
    LinkedData.config do |config, overide_connect_goo|
      # Prevent goo connection
      overide_connect_goo = true
      # Settings
      config.goo_port = test_port
      config.goo_host = test_host
    end

    assert_equal(test_host, LinkedData.settings.goo_host, msg="goo_host != test_host")
    assert_equal(test_port, LinkedData.settings.goo_port, msg="goo_port != test_port")
    assert_equal(false, Goo.sparql_data_client.nil?, msg='sparql_data_client is nil')
    assert_equal(false, Goo.sparql_update_client.nil?, msg='sparql_update_client is nil')
    assert_equal(false, Goo.sparql_query_client.nil?, msg='sparql_query_client is nil')
  end

end
