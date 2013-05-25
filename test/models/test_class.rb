require_relative "./test_ontology_common"
require "logger"

class TestClassModel < LinkedData::TestOntologyCommon

  def test_class_parents
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where(ontology: [ acronym: acr ], 
                                                      submissionId: 1).all
    assert(os.length == 1)
    os = os[0]

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_7"
    cls = LinkedData::Models::Class.find(class_id).in(os).include(:parents).to_a[0]

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
    cls.bring(:ancestors)
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
    os = LinkedData::Models::OntologySubmission.where(ontology: [ acronym: acr ], 
                                                      submissionId: 1).all
    assert(os.length == 1)
    os = os[0]

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class1"

    cls = LinkedData::Models::Class.find(class_id).in(os)
                .include(:parents)
                .include(:children)
                .to_a[0]
    children = cls.children
    assert_equal(1, cls.children.length)
    children_id = "http://bioportal.bioontology.org/ontologies/msotes#class2"
    assert_equal(children_id,cls.children[0].resource_id.value)

    #they should have the same submission
    assert_equal(cls.children[0].submission, os)

    #transitive
    descendants = cls.descendants
    descendants.map! { |a| a.resource_id.value }
    data_descendants = ["http://bioportal.bioontology.org/ontologies/msotes#class_5",
 "http://bioportal.bioontology.org/ontologies/msotes#class2",
    "http://bioportal.bioontology.org/ontologies/msotes#class_7"]
    assert descendants.sort == data_descendants.sort

  end

  def test_path_to_root
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr

    os = LinkedData::Models::OntologySubmission.where(ontology: [ acronym: acr ], 
                                                      submissionId: 1).all
    assert(os.length == 1)
    os = os[0]

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_7"

    cls = LinkedData::Models::Class.find(class_id).in(os).first

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

    os = LinkedData::Models::OntologySubmission.where(ontology: [ acronym: acr ], 
                                                      submissionId: 1).all
    assert(os.length == 1)
    os = os[0]

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class_5"
    cls = LinkedData::Models::Class.find(class_id).in(os).first

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
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    assert(os.length == 1)
    os = os[0]

    class_id = RDF::IRI.new "http://bioportal.bioontology.org/ontologies/msotes#class2"
    cls = LinkedData::Models::Class.find(class_id, submission: os , load_attrs: :all)
    assert (cls.attributes[:versionInfo][0].value == "some version info")
    assert (cls.attributes[RDF::IRI.new("http://www.w3.org/2002/07/owl#versionInfo")][0].value == "some version info")
  end

  def test_children_count
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr },
      :submissionId => 1
    clss = LinkedData::Models::Class.where submission: os[0], load_attrs: { prefLabel: true, childrenCount: true }
    clss.each do |c|
      if c.resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class1"
        assert c.childrenCount == 1
      elsif c.resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class2"
        assert c.childrenCount == 2
      elsif c.resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class3"
        assert c.childrenCount == 1
      elsif c.resource_id.value == "http://bioportal.bioontology.org/ontologies/msotes#class4"
        assert c.childrenCount == 2
      else
        assert c.childrenCount == 0
      end
    end
  end

  def test_class_nil_values
    cls = LinkedData::Models::Class.new
    cls.my_new_attr = "blah"
    assert cls.my_new_attr == ["blah"]
  end

  def test_bro_tree
    #just one path with children
    if !LinkedData::Models::Ontology.find("BROTEST123")
      submission_parse("BROTEST123", "SOME BROTEST Bla", "./test/data/ontology_files/BRO_v3.2.owl", 123)
    end
    os = LinkedData::Models::Ontology.find("BROTEST123").latest_submission
    statistical_Text_Analysis = "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Statistical_Text_Analysis"
    cls = LinkedData::Models::Class.find(RDF::IRI.new(statistical_Text_Analysis), submission: os)

    root_backend = cls.tree
    root_backend.resource_id.value == "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource"
    tree_backend = root_backend
    root_backend.children.each do |c|
      assert c.childrenCount > 0
    end
    levels = 0
    while tree_backend and tree_backend.children.length > 0 do
      cc = 0
      next_tree = nil
      tree_backend.children.each do |c|
        assert c.childrenCount != nil
        assert c.prefLabel != nil
        next_tree = c if c.children.length > 0
      end
      assert cc < 2
      if next_tree.nil?
        tree_backend.children.select { |x| x.resource_id.value == "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Statistical_Text_Analysis" }.length == 1
        assert tree_backend.children.length == 2
        assert tree_backend.children.first.childrenCount == 0
        assert tree_backend.children[1].childrenCount == 0
      end
      tree_backend = next_tree
      levels += 1
    end
  end


  def test_include_ancestors
   if !LinkedData::Models::Ontology.find("BROTEST123")
      submission_parse("BROTEST123", "SOME BROTEST Bla", "./test/data/ontology_files/BRO_v3.2.owl", 123)
    end
    os = LinkedData::Models::Ontology.find("BROTEST123").latest_submission
 statistical_Text_Analysis = "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Statistical_Text_Analysis"
    cls = LinkedData::Models::Class.find(RDF::IRI.new(statistical_Text_Analysis), submission: os,load_attrs: [ :ancestors => true, :prefLabel => true ], query_options: { rules: "SUBP+SUBC"})
    assert cls.attributes[:ancestors].length == 3
    assert_instance_of String, cls.attributes[:prefLabel].value
  end

  def test_bro_paths_to_root
    if !LinkedData::Models::Ontology.find("BROTEST123")
      submission_parse("BROTEST123", "SOME BROTEST Bla", "./test/data/ontology_files/BRO_v3.2.owl", 123)
    end
    os = LinkedData::Models::Ontology.find("BROTEST123").latest_submission
    statistical_Text_Analysis = "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Statistical_Text_Analysis"
    cls = LinkedData::Models::Class.find(RDF::IRI.new(statistical_Text_Analysis), submission: os)

    paths_backend = cls.paths_to_root
    paths = []
    paths_backend.each do |pb|
      paths << pb.map { |x| x.resource_id.value }
    end

    path_0 = ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Statistical_Text_Analysis",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Text_Mining",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Mining_and_Inference",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Analysis_Software",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Software",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource"].reverse

    path_1 = ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Statistical_Text_Analysis",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Text_Mining",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Natural_Language_Processing",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Analysis_Software",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Software",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource"].reverse

    path_2 = ["http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Statistical_Text_Analysis",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Text_Mining",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Mining_and_Inference",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Statistical_Analysis",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Analysis_Software",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Software",
 "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Resource"].reverse

    paths.each do |path|
      assert (path == path_0 || path == path_1 || path == path_2)
    end
    assert paths.length == 3
    assert paths[0] != paths[1]
    assert paths[1] != paths[2]
    assert paths[0] != paths[2]

  end

end
