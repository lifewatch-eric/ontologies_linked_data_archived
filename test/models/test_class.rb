require_relative "./test_ontology_common"
require "logger"

class TestClassModel < LinkedData::TestOntologyCommon

  def setup
  end

  def test_terms_custom_props
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr }, :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load
    os_classes = os.classes
    os_classes.each do |c|
      assert(!c.prefLabel.nil?, "Class #{c.id.value} does not have a label")
    end
    os.ontology.load
    os.ontology.delete
    os.delete
  end
end
