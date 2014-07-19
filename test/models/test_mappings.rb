require_relative "./test_ontology_common"
require "logger"

class TestMapping < LinkedData::TestOntologyCommon


  ONT_ACR1 = 'MAPPING_TEST1'
  ONT_ACR2 = 'MAPPING_TEST2'
  ONT_ACR3 = 'MAPPING_TEST3'
  ONT_ACR4 = 'MAPPING_TEST4'


  def self.before_suite
    if LinkedData::Models::Mapping.all.length > 100
      puts "KB with too many mappings to run test. Is this pointing to a TEST KB?"
      raise Exception, "KB with too many mappings to run test. Is this pointing to a TEST KB?"
    end

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

  def test_loom
    #bro
    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR1 }).to_a[0]
    #fake ont
    ont2 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR4 }).to_a[0]

    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ont1 ])
                                 .and(terms: [ontology: ont2 ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name])
                                 .all
    mappings.each do |map|
      bro_term = map.terms.select { |x| x.ontology.acronym == ONT_ACR1 }.first
      fake_term = map.terms.select { |x| x.ontology.acronym == ONT_ACR4 }.first

      #it would get map on syn <-> syn
      assert(fake_term.term.first.to_s !=
              "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/nomapped")


      if fake_term.term.first.to_s ==
          "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf"
        assert bro_term.term.first.to_s ==
                "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Federal_Funding_Resource"
      elsif fake_term.term.first.to_s ==
            "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/Material_Resource"
        assert bro_term.term.first.to_s ==
          "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Material_Resource"
      elsif fake_term.term.first.to_s ==
              "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/dataprocess"
        assert bro_term.term.first.to_s ==
          "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Data_Processing_Software"
      elsif fake_term.term.first.to_s ==
              "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/process"
        assert bro_term.term.first.to_s ==
          "http://bioontology.org/ontologies/Activity.owl#Activity"
      elsif fake_term.term.first.to_s ==
              "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/Funding"
        assert bro_term.term.first.to_s ==
          "http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Funding_Resource"
      else
        assert 1!=0, "Outside of controlled set of mappings"
      end
    end
    term_mapping_count = LinkedData::Models::TermMapping.where.all.length
    assert term_mapping_count == 10

    #testing for same process
    $MAPPING_RELOAD_LABELS = true
    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR2 }).to_a[0] #CNO
    ont2 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR4 }).to_a[0] #fake ont

    process_count = LinkedData::Models::MappingProcess.where.all.length
    begin
      tmp_log = Logger.new(TestLogFile.new)
      loom = LinkedData::Mappings::Loom.new(ont1, ont2,tmp_log)
    rescue Exception => e
      puts "Error, logged in #{tmp_log.instance_variable_get("@logdev").dev.path}"
      raise e
    end

    loom.start()
    new_term_mapping_count = LinkedData::Models::TermMapping.where.all.length
    #this process only adds two TermMappings
    assert new_term_mapping_count == 14

    #process has been reused
    assert process_count == LinkedData::Models::MappingProcess.where.all.length

    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ont1 ])
                                 .and(terms: [ontology: ont2 ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name])
                                 .all
    assert mappings.length == 3
    mappings.each do |map|
      cno_term = map.terms.select { |x| x.ontology.acronym == ONT_ACR2 }.first
      fake_term = map.terms.select { |x| x.ontology.acronym == ONT_ACR4 }.first
      if fake_term.term.first.to_s ==
          "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/defined_type_of_model"
        assert cno_term.term.first.to_s ==
            "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000001"
      elsif fake_term.term.first.to_s ==
            "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf"
        assert cno_term.term.first.to_s ==
          "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#fakething"
      elsif fake_term.term.first.to_s ==
          "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/process"
        assert cno_term.term.first.to_s ==
          "http://www.ifomis.org/bfo/1.1/span#Process"
      else
        assert 1!=0, "Outside of controlled set of mappings"
      end
    end

    #no new term mappings for fake ont need to be created
    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR2 }).to_a[0] #CNO
    ont2 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR1 }).to_a[0] #bro

    #one new mapping is created but TermMappings are the same
    begin
      tmp_log = Logger.new(TestLogFile.new)
      loom = LinkedData::Mappings::Loom.new(ont1, ont2,tmp_log)
    rescue Exception => e
      puts "Error, logged in #{tmp_log.instance_variable_get("@logdev").dev.path}"
      raise e
    end

    loom.start()
    #same number - new mappingterms no created
    assert new_term_mapping_count == 14
    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ont1 ])
                                 .and(terms: [ontology: ont2 ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name])
                                 .all
    assert mappings.length == 3
    mappings.each do |map|
      cno_term = map.terms.select { |x| x.ontology.acronym == ONT_ACR2 }.first
      bro_term = map.terms.select { |x| x.ontology.acronym == ONT_ACR1 }.first
      if bro_term.term.first.to_s["Network_Model"] || bro_term.term.first.to_s["Network_model"]
        assert cno_term.term.first.to_s["cno_0000010"]
      elsif bro_term.term.first.to_s["Federal_Funding_Resource"]
        assert cno_term.term.first.to_s["fakething"]
      else
        assert 1!=0, "Outside of controlled set of mappings"
      end
    end

    counts_ont1 = LinkedData::Mappings.mapping_counts_for_ontology(ont1)
    assert counts_ont1 == {"MAPPING_TEST1"=>3, "MAPPING_TEST4"=>3}
    counts_all = LinkedData::Mappings.mapping_counts_per_ontology()
    assert counts_all == {"MAPPING_TEST1"=>8, "MAPPING_TEST2"=>6, "MAPPING_TEST4"=>8}
  end

  def test_cui
    LinkedData::Models::MappingProcess.all.each do |p|
      p.delete
    end
    LinkedData::Models::TermMapping.all.each do |map|
      map.delete
    end
    LinkedData::Models::Mapping.all.each do |map|
      map.delete
    end

    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR2 }).to_a[0] #cno
    ont2 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR4 }).to_a[0] #fake ont

    begin
      tmp_log = Logger.new(TestLogFile.new)
      cui = LinkedData::Mappings::CUI.new(ont1, ont2,tmp_log)
    rescue Exception => e
      puts "Error, logged in #{tmp_log.instance_variable_get("@logdev").dev.path}"
      raise e
    end

    cui.start()

    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ont1 ])
                                 .and(terms: [ontology: ont2 ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name])
                                 .all
    #there are two terms in CNO mapping to one.
    #that is why there are 5 termmappings for 3 mappings
    assert LinkedData::Models::TermMapping.where.all.length == 5
    assert mappings.length == 3
    cno_terms =
      [ "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000194",
       "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#fakething",
        "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000160"]
    fake_terms =
      ["http://www.semanticweb.org/manuelso/ontologies/mappings/fake/onlycui",
         "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf",
          "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf"]
    mappings.each do |map|
       cno = map.terms.select { |x| x.ontology.acronym == ONT_ACR2 }.first
       fake = map.terms.select { |x| x.ontology.acronym == ONT_ACR4 }.first
       if cno.term.first.to_s ==
         "http://purl.org/incf/ontology/Computational_Neurosciences/cno_alpha.owl#cno_0000160"
         assert fake.term.first.to_s ==
           "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf"
       else
         assert(cno_terms.index(cno.term.first.to_s) ==
                   fake_terms.index(fake.term.first.to_s))
       end
       assert cno_terms.index(cno.term.first.to_s)
       assert fake_terms.index(fake.term.first.to_s)
    end
    assert LinkedData::Models::MappingProcess.all.length == 1
    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR1 }).to_a[0] #bro
    ont2 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR4 }).to_a[0] #fake ont
    $MAPPING_RELOAD_LABELS = false
    begin
      tmp_log = Logger.new(TestLogFile.new)
      cui = LinkedData::Mappings::CUI.new(ont1, ont2,tmp_log)
    rescue Exception => e
      puts "Error, logged in #{tmp_log.instance_variable_get("@logdev").dev.path}"
      raise e
    end

    cui.start()
    assert LinkedData::Models::MappingProcess.all.length == 1
    assert LinkedData::Models::Mapping.all.length == 4
    assert LinkedData::Models::TermMapping.all.length == 6

    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ont1 ])
                                  .and(terms: [ontology: ont2 ])
                                  .include(terms: [ :term, ontology: [ :acronym ] ])
                                  .include(process: [:name])
                                  .all
    assert mappings.length == 1
    map = mappings.first
    bro = map.terms.select { |x| x.ontology.acronym == ONT_ACR1 }.first
    fake = map.terms.select { |x| x.ontology.acronym == ONT_ACR4 }.first
    assert bro.term.first.to_s ==
              "http://bioontology.org/ontologies/Activity.owl#IRB"
    assert fake.term.first.to_s ==
              "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/federalf"
  end

  def test_uri
    LinkedData::Models::MappingProcess.all.each do |p|
      p.delete
    end
    LinkedData::Models::TermMapping.all.each do |map|
      map.delete
    end
    LinkedData::Models::Mapping.all.each do |map|
      map.delete
    end

    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR1 }).to_a[0] #bro
    ont2 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR2 }).to_a[0] #cno

    $MAPPING_RELOAD_LABELS = true
    begin
      tmp_log = Logger.new(TestLogFile.new)
      cui = LinkedData::Mappings::SameURI.new(ont1, ont2,tmp_log)
    rescue Exception => e
      puts "Error, logged in #{tmp_log.instance_variable_get("@logdev").dev.path}"
      raise e
    end

    cui.start()

    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ont1 ])
                                 .and(terms: [ontology: ont2 ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name])
                                 .all
    assert LinkedData::Models::TermMapping.where.all.length == 10
    assert mappings.length == 5
    mappings.each do |map|
      cno = map.terms.select { |x| x.ontology.acronym == ONT_ACR2 }.first
      bro = map.terms.select { |x| x.ontology.acronym == ONT_ACR1 }.first
      assert cno.term.first.to_s == bro.term.first.to_s
    end
    assert LinkedData::Models::MappingProcess.all.length == 1
  end

  def test_xref
    LinkedData::Models::MappingProcess.all.each do |p|
      p.delete
    end
    LinkedData::Models::TermMapping.all.each do |map|
      map.delete
    end
    LinkedData::Models::Mapping.all.each do |map|
      map.delete
    end

    ont1 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR4 }).to_a[0] #fake
    ont2 = LinkedData::Models::Ontology.where({ :acronym => ONT_ACR1 }).to_a[0] #bro

    $MAPPING_RELOAD_LABELS = true
    begin
      tmp_log = Logger.new(TestLogFile.new)
      xref = LinkedData::Mappings::XREF.new(ont1, ont2,tmp_log)
    rescue Exception => e
      puts "Error, logged in #{tmp_log.instance_variable_get("@logdev").dev.path}"
      raise e
    end

    xref.start()

    mappings = LinkedData::Models::Mapping.where(terms: [ontology: ont1 ])
                                 .and(terms: [ontology: ont2 ])
                                 .include(terms: [ :term, ontology: [ :acronym ] ])
                                 .include(process: [:name])
                                 .all

    assert LinkedData::Models::TermMapping.where.all.length == 4
    assert mappings.length == 2
    mappings.each do |map|
      fake = map.terms.select { |x| x.ontology.acronym == ONT_ACR4 }.first
      bro = map.terms.select { |x| x.ontology.acronym == ONT_ACR1 }.first
      if bro.term.first.to_s["Biositemaps_Information_Model"]
        assert fake.term.first.to_s ==
          "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/process"
      elsif bro.term.first.to_s["Information_Resource"]
        assert fake.term.first.to_s ==
          "http://www.semanticweb.org/manuelso/ontologies/mappings/fake/Material_Resource"
      else
        assert 1==0, "XREF mapping error. Uncontrolled mapping"
      end
    end
    assert LinkedData::Models::MappingProcess.all.length == 1
  end
end
