require "test/unit"
require_relative "../../lib/ontologies_linked_data"

class TestLinkedDataSerializer < Test::Unit::TestCase
  def teardown
    Goo.class_variable_set("@@_default_store", nil)
    LinkedData.instance_variable_set("@settings_run", false)
    SparqlRd::Repository.class_variable_set("@@instances", {})
    load(File.expand_path("../../../config/config.rb", __FILE__))
  end

  def test_default_config
    Goo.class_variable_set("@@_default_store", nil)
    LinkedData.instance_variable_set("@settings_run", false)
    LinkedData.config()
    assert LinkedData.settings.goo_host == "localhost"
    assert LinkedData.settings.goo_port == 9000
    assert (not Goo.store.nil?)
  end

  def test_custom_config
    test_port = 1
    test_host = "test_host"

    # Override safety check
    LinkedData.instance_variable_set("@settings_run", false)

    # Re-configure
    LinkedData.config do |config, overide_connect_goo|
      # Prevent goo connection
      overide_connect_goo = true
      # Settings
      config.goo_port = test_port
      config.goo_host = test_host
    end

    assert LinkedData.settings.goo_host == test_host
    assert LinkedData.settings.goo_port == test_port
    assert (not Goo.store.nil?)
  end
end