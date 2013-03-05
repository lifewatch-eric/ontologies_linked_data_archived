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
    os_classes = os.classes :load_attrs => [:prefLabel]
    os_classes.each do |c|
      assert(!c.prefLabel.nil?, "Class #{c.resource_id.value} does not have a label")
    end
  end

  def test_class_parents
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr }, :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_7"
    cls = LinkedData::Models::Class.find(class_id, submission: os )

    pp = cls.parents[0]
    assert pp.parents.length == 1

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    cls = LinkedData::Models::Class.find(class_id, submission: os )
    parents = cls.parents
    assert_equal(parents, cls.parents)
    assert_equal(2, cls.parents.length)
    parent_ids = [ "http://bioportal.bioontology.org/ontologies/msotes#class2",
      "http://bioportal.bioontology.org/ontologies/msotes#class4" ]
    parent_id_db = cls.parents.map { |x| x.resource_id.value }
    assert_equal(parent_id_db.sort, parent_ids.sort)

    assert !cls.parents[0].submission.nil?
    #they should have the same submission
    assert_equal(cls.parents[0].submission, os)

    #transitive
    ancestors = cls.ancestors
    ancestors.each do |a|
      assert !a.submission.nil?
    end
    assert ancestors.length == cls.ancestors.length
    ancestors.select! { |b| !b.resource_id.bnode? }
    ancestors.map! { |a| a.resource_id.value }
    data_ancestors = ["http://bioportal.bioontology.org/ontologies/msotes#class1",
 "http://bioportal.bioontology.org/ontologies/msotes#class2",
 "http://bioportal.bioontology.org/ontologies/msotes#class4",
 "http://bioportal.bioontology.org/ontologies/msotes#class3"   ]
    assert ancestors.sort == data_ancestors.sort

  end

  def test_class_children
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class1"
    cls = LinkedData::Models::Class.find(class_id, submission: os )
    assert cls.prefLabel == 'class 1 literal'
    children = cls.children
    assert_equal(1, cls.children.length)
    children_id = "http://bioportal.bioontology.org/ontologies/msotes#class2"
    assert_equal(children_id,cls.children[0].resource_id.value)

    #they should have the same submission
    assert_equal(cls.children[0].submission, os)

    #transitive
    descendents = cls.descendents
    descendents.map! { |a| a.resource_id.value }
    data_descendents = ["http://bioportal.bioontology.org/ontologies/msotes#class_5",
 "http://bioportal.bioontology.org/ontologies/msotes#class2",
    "http://bioportal.bioontology.org/ontologies/msotes#class_7"]
    assert descendents.sort == data_descendents.sort

  end

  def test_path_to_root
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_7"
    cls = LinkedData::Models::Class.find(class_id, submission: os )

    paths = cls.paths_to_root
    assert paths.length == 1
    path = paths[0]
    assert path.length == 3
    assert path[0].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class_7"
    assert path[1].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class2"
    assert path[2].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class1"

  end

  def test_path_to_root_with_multiple_parents
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    cls = LinkedData::Models::Class.find(class_id, submission: os )

    paths = cls.paths_to_root
    assert paths.length == 2
    path = paths[1]
    assert path.length == 3
    assert path[0].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    assert path[1].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class2"
    assert path[2].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class1"
    path = paths[0]
    assert path.length == 3
    assert path[0].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    assert path[1].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class4"
    assert path[2].resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class3"

  end

  def test_class_all_attributes
    skip("Waiting for 'all_attributes' attribute support...")
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    assert(os.length == 1)
    os = os[0]
    os.load unless os.loaded?

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class2"
    cls = LinkedData::Models::Class.find(class_id, submission: os )
    #cls.load_attributes
    assert (cls.attributes["http://www.w3.org/2002/07/owl#versionInfo"][0].value == "some version info")

  end
end
