require_relative "../test_case"

class TestGroup < LinkedData::TestCase

  def test_ontology_format_equal
    this = LinkedData::Models::OntologyFormat.find('OWL').first
    that = LinkedData::Models::OntologyFormat.find('OWL').first
    assert(!this.nil?, msg="OntologyFormat failed to find OWL.")
    assert(!that.nil?, msg="OntologyFormat failed to find OWL.")
    assert_equal(this, that, msg="OntologyFormat 'OWL' failing equality test.")
    assert_equal(this, "OWL", msg="OntologyFormat 'OWL' failing equality test.")
    assert(this.owl?, msg="OntologyFormat failing .owl? test.")
  end

end
