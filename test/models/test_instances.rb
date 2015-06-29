require_relative "./test_ontology_common"
require "logger"

class TestInstances < LinkedData::TestOntologyCommon


  def self.before_suite
    LinkedData::TestCase.backend_4s_delete
  end

  def test_instances
    submission_parse("TESTINST", "Testing instances",
                     "test/data/ontology_files/XCTontologyvtemp2_vvtemp2.zip",
                     12,
                     masterFileName: "XCTontologyvtemp2/XCTontologyvtemp2.owl",
                     process_rdf: true, index_search: false,
                     run_metrics: false, reasoning: true)
    submission_id = LinkedData::Models::OntologySubmission.all.first.id
    class_id = RDF::URI.new(
      "http://www.owl-ontologies.com/OntologyXCT.owl#ClinicalManifestation")
    instances = LinkedData::InstanceLoader.get_instances(submission_id,class_id)
    assert (instances.length == 385)
    instances.each do |inst|
      assert (not inst.label.nil?)
      assert (not inst.id.nil?)
    end
  end


end
