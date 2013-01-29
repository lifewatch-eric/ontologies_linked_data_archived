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
      assert(!c.prefLabel.nil?, "Class #{c.resource_id.value} does not have a label")
    end
    os.ontology.load
    os.ontology.delete
    os.delete
  end

  def test_class_where_id
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr }, :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?
    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    classes = LinkedData::Models::Class.where( :submission => os, :resource_id => class_id )
    assert_instance_of(Array, classes)
    assert(classes.length == 1)
    assert_instance_of(LinkedData::Models::Class, classes[0])
    cls = classes[0]
    assert_equal 'class 5 pref label', cls.prefLabel.value
    assert_equal 0, cls.synonymLabel.length

    os.ontology.load
    os.ontology.delete
    os.delete
  end

  def test_class_parents
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    #init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr }, :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    classes = LinkedData::Models::Class.where( :submission => os, :resource_id => class_id )
    assert(classes.length == 1)
    cls = classes[0]
    assert(!cls.loaded_parents?)
    begin
      cls.parents
      assert(1 == 0)
    rescue => e
      #parent not loaded expection
      assert_instance_of(ArgumentError, e)
    end
    parents = cls.load_parents
    assert(cls.loaded_parents?)
    assert_equal(parents, cls.parents)
    assert_equal(1, cls.parents.length)
    parent_id = "http://bioportal.bioontology.org/ontologies/msotes#class2"
    assert_equal(parent_id,cls.parents[0].resource_id.value)

    #they should have the same submission
    assert_equal(cls.parents[0].submission, os)

    os.ontology.load
    os.ontology.delete
    os.delete
  end

end
