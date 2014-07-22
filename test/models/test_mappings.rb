require_relative "./test_ontology_common"
require "logger"

class TestMapping < LinkedData::TestOntologyCommon


  ONT_ACR1 = 'MAPPING_TEST1'
  ONT_ACR2 = 'MAPPING_TEST2'
  ONT_ACR3 = 'MAPPING_TEST3'
  ONT_ACR4 = 'MAPPING_TEST4'


  def self.before_suite
    LinkedData::TestCase.backend_4s_delete
    ontologies_parse()
  end

  def self.ontologies_parse()
    helper = LinkedData::TestOntologyCommon.new(self)
    helper.submission_parse(ONT_ACR1,
                     "MappingOntTest1",
                     "./test/data/ontology_files/BRO_v3.3.owl", 11,
                     process_rdf: true, index_search: false,
                     run_metrics: false, reasoning: true)
    helper.submission_parse(ONT_ACR2,
                     "MappingOntTest2",
                     "./test/data/ontology_files/CNO_05.owl", 22,
                     process_rdf: true, index_search: false,
                     run_metrics: false, reasoning: true)
    helper.submission_parse(ONT_ACR3,
                     "MappingOntTest3",
                     "./test/data/ontology_files/aero.owl", 33,
                     process_rdf: true, index_search: false,
                     run_metrics: false, reasoning: true)
    helper.submission_parse(ONT_ACR4,
                     "MappingOntTest4",
                     "./test/data/ontology_files/fake_for_mappings.owl", 44,
                     process_rdf: true, index_search: false,
                     run_metrics: false, reasoning: true)
  end

  def get_process(name)
    #just some user
    user = LinkedData::Models::User.where.include(:username).all[0]

    #process
    ps = LinkedData::Models::MappingProcess.where({:name => name })
    ps.each do |p|
      p.delete
    end
    p = LinkedData::Models::MappingProcess.new(:creator => user, :name => name)
    assert p.valid?
    p.save
    ps = LinkedData::Models::MappingProcess.where({:name => name }).to_a
    assert ps.length == 1
    return ps[0]
  end

  def validate_mapping(map)
    prop = map.type.downcase.to_sym
    prop = :prefLabel if map.type == "LOOM"
    prop = nil if map.type == "SAME_URI"

    classes = []
    map.terms.each do |t|
      sub = LinkedData::Models::OntologySubmission.find(t.submissionId).first
      cls = LinkedData::Models::Class.find(t.classId).in(sub)
      unless prop.nil?
        cls.include(prop)
      end
      cls = cls.first
      classes << cls unless cls.nil?
    end
    if map.type == "SAME_URI"
      return classes[0].id.to_s == classes[1].id.to_s
    end
    if map.type == "XREF"
      return classes[0].xref == classes[1].xref
    end
    if map.type == "LOOM"
      ldOntSub = LinkedData::Models::OntologySubmission
      label0 = ldOntSub.loom_transform_literal(classes[0].prefLabel)
      label1 = ldOntSub.loom_transform_literal(classes[1].prefLabel)
      return label0 == label1
    end
    if map.type == "CUI"
      return classes[0].cui == classes[1].cui
    end
    return false
  end

  def test_mappings_ontology
    #bro
    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR1 }).to_a[0]

    latest_sub = ont1.latest_submission
    mappings = LinkedData::Mappings.mappings_ontology(latest_sub,1, 100)
    cui = 0
    xref = 0
    same_uri = 0
    loom = 0
    mappings.each do |map|
      assert_equal(map.terms[0].submissionId.to_s, latest_sub.id.to_s)
      if map.type == "CUI"
        cui += 1
      elsif map.type == "XREF"
        xref += 1
      elsif map.type == "SAME_URI"
        same_uri += 1
      elsif map.type == "LOOM"
        loom += 1
      else
        assert 1 == 0, "unknown type for this ontology #{map.type}"
      end
      assert validate_mapping(map), "mapping is not valid"
    end
    assert_equal(mappings.length, 29)
    assert_equal(same_uri,10)
    assert_equal(cui, 3)
    assert_equal(xref,2)
    assert_equal(loom,14)
  end

  def test_mappings_two_ontologies
    #bro
    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR1 }).to_a[0]
    #fake ont
    ont2 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR4 }).to_a[0]

    latest_sub1 = ont1.latest_submission
    latest_sub2 = ont2.latest_submission
    mappings = LinkedData::Mappings.mappings_ontologies(latest_sub1, latest_sub2,
                                                        1, 100)
    cui = 0
    xref = 0
    same_uri = 0
    loom = 0
    mappings.each do |map|
      assert_equal(map.terms[0].submissionId.to_s, latest_sub1.id.to_s)
      assert_equal(map.terms[1].submissionId.to_s, latest_sub2.id.to_s)
      if map.type == "CUI"
        cui += 1
      elsif map.type == "XREF"
        xref += 1
      elsif map.type == "SAME_URI"
        same_uri += 1
      elsif map.type == "LOOM"
        loom += 1
      else
        assert 1 == 0, "unknown type for this ontology #{map.type}"
      end
      assert validate_mapping(map), "mapping is not valid"
    end
    assert_equal(mappings.length, 10)
    assert_equal(same_uri,5)
    assert_equal(cui, 1)
    assert_equal(xref,2)
    assert_equal(loom,2)
  end

end
