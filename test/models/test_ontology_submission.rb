require_relative "./test_ontology_common"
require "logger"

class TestOntologySubmission < LinkedData::TestOntologyCommon
  def setup
  end

  def teardown
    l = LinkedData::Models::Ontology.all
    if l.length > 50
      raise ArgumentError, "Too many ontologies in triple store. TESTS WILL DELETE DATA"
    end
    l.each do |os|
      os.load
      os.delete
    end
  end

  def test_valid_ontology
    return if ENV["SKIP_PARSING"]

    acronym = "SNOMED-TST"
    name = "SNOMED-CT TEST"
    ontologyFile = "./test/data/ontology_files/BRO_v3.2.owl"
    id = 10

    owl, bogus, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)

    os = LinkedData::Models::OntologySubmission.new
    assert (not os.valid?)

    bogus.acronym = acronym
    os.submissionId = id
    os.contact = contact
    os.released = DateTime.now - 4
    bogus.name = name
    o = LinkedData::Models::Ontology.find(acronym)
    if o.nil?
      os.ontology = LinkedData::Models::Ontology.new(:acronym => acronym)
    else
      os.ontology = o
    end
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id, ontologyFile)
    os.uploadFilePath = uploadFilePath
    os.hasOntologyLanguage = owl
    bogus.administeredBy = user
    os.ontology = bogus
    os.submissionStatus = status
    assert os.valid?
  end

  def test_sanity_check_single_file_submission
    return if ENV["SKIP_PARSING"]

    acronym = "BRO"
    name = "Biomedical Resource Ontology"
    ontologyFile = "./test/data/ontology_files/BRO_v3.2.owl"
    id = 10

    owl, bro, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)

    ont_submision =  LinkedData::Models::OntologySubmission.new({:acronym => acronym, :submissionId => id})
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id, ontologyFile)
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.uploadFilePath = uploadFilePath
    ont_submision.submissionStatus = status
    assert (not ont_submision.valid?)
    assert_equal 2, ont_submision.errors.length
    assert_instance_of Array, ont_submision.errors[:ontology]
    assert_instance_of Array, ont_submision.errors[:hasOntologyLanguage]
    ont_submision.hasOntologyLanguage = owl
    bro.administeredBy = user
    ont_submision.ontology = bro
    assert ont_submision.valid?
    assert_equal 0, ont_submision.errors.length
  end


  def test_sanity_check_zip
    return if ENV["SKIP_PARSING"]

    acronym = "RADTEST"
    name = "RADTEST Bla"
    ontologyFile = "./test/data/ontology_files/SDO.zip"
    id = 10

    teardown

    owl, rad, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)

    ont_submision =  LinkedData::Models::OntologySubmission.new({:acronym => acronym, :submissionId => id,})
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id, ontologyFile)
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.uploadFilePath = uploadFilePath
    ont_submision.hasOntologyLanguage = owl
    rad.administeredBy = user
    ont_submision.ontology = rad
    ont_submision.submissionStatus = status
    assert (not ont_submision.valid?)
    assert_equal 1, ont_submision.errors.length
    assert_instance_of Hash, ont_submision.errors[:uploadFilePath][0]
    assert_instance_of Array, ont_submision.errors[:uploadFilePath][0][:options]
    assert_instance_of String, ont_submision.errors[:uploadFilePath][0][:message]
    assert (ont_submision.errors[:uploadFilePath][0][:options].length > 0)
    ont_submision.masterFileName = "does not exist"
    ont_submision.valid?
    assert_instance_of Hash, ont_submision.errors[:uploadFilePath][0]
    assert_instance_of Array, ont_submision.errors[:uploadFilePath][0][:options]
    assert_instance_of String, ont_submision.errors[:uploadFilePath][0][:message]

    #choose one from options.
    ont_submision.masterFileName = ont_submision.errors[:uploadFilePath][0][:options][0]
    assert ont_submision.valid?
    assert_equal 0, ont_submision.errors.length
  end

  def test_duplicated_file_names
    return if ENV["SKIP_PARSING"]

    acronym = "DUPTEST"
    name = "DUPTEST Bla"
    ontologyFile = "./test/data/ontology_files/ont_dup_names.zip"
    id = 10

    owl, dup, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => acronym, :submissionId => 1,})
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id, ontologyFile)
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.hasOntologyLanguage = owl
    dup.administeredBy = user
    ont_submision.ontology = dup
    assert (!ont_submision.valid?)
    assert_equal 2, ont_submision.errors.length
    assert_instance_of String, ont_submision.errors[:uploadFilePath][0]
    assert_instance_of String, ont_submision.errors[:submissionStatus][0]
  end

  def test_submission_parse
    return if ENV["SKIP_PARSING"]

    acronym = "BROTEST"
    name = "BROTEST Bla"
    ontologyFile = "./test/data/ontology_files/BRO_v3.2.owl"
    id = 10

    bro = LinkedData::Models::Ontology.find(acronym)
    if not bro.nil?
      sub = bro.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => acronym, :submissionId => id, :name => name })
    assert (not ont_submision.valid?)
    assert_equal 6, ont_submision.errors.length
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id, ontologyFile)
    ont_submision.uploadFilePath = uploadFilePath
    owl, bro, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)
    bro.administeredBy = user
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.hasOntologyLanguage = owl
    ont_submision.ontology = bro
    ont_submision.submissionStatus = status
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)
    uploaded = LinkedData::Models::SubmissionStatus.find("UPLOADED")
    uploded_ontologies = uploaded.submissions
    uploaded_ont = nil
    uploded_ontologies.each do |ont|
      ont.load unless ont.loaded?
      ont.ontology.load unless ont.ontology.loaded?
      if ont.ontology.acronym == acronym
        uploaded_ont = ont
      end
    end
    assert (not uploaded_ont.nil?)
    if not uploaded_ont.ontology.loaded?
      uploaded_ont.ontology.load
    end
    uploaded_ont.process_submission Logger.new(STDOUT)
  end

  def test_submission_parse_zip
    return if ENV["SKIP_PARSING"]

    acronym = "RADTEST"
    name = "RADTEST Bla"
    ontologyFile = "./test/data/ontology_files/radlex_owl_v3.0.1.zip"
    id = 10

    bro = LinkedData::Models::Ontology.find(acronym)
    if not bro.nil?
      sub = bro.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end

    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => acronym, :submissionId => id,})
    assert (not ont_submision.valid?)
    assert_equal 6, ont_submision.errors.length
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id,ontologyFile)
    ont_submision.uploadFilePath = uploadFilePath
    owl, bro, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)
    bro.administeredBy = user
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.hasOntologyLanguage = owl
    ont_submision.ontology = bro
    ont_submision.submissionStatus = status
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)
    uploaded = LinkedData::Models::SubmissionStatus.find("UPLOADED")
    uploded_ontologies = uploaded.submissions
    uploaded_ont = nil
    uploded_ontologies.each do |ont|
      ont.load unless ont.loaded?
      ont.ontology.load unless ont.ontology.loaded?
      if ont.ontology.acronym == acronym
        uploaded_ont = ont
      end
    end
    assert (not uploaded_ont.nil?)
    if not uploaded_ont.ontology.loaded?
      uploaded_ont.ontology.load
    end
    uploaded_ont.process_submission Logger.new(STDOUT)
    assert uploaded_ont.submissionStatus.parsed?

    uploaded_ont.classes(:load_attrs => [:prefLabel]).each do |cls|
      assert(cls.prefLabel != nil, "Class #{cls.resource_id} does not have a label")
      assert_instance_of String, cls.prefLabel.value
    end
  end

  def test_custom_property_generation
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr

    o = LinkedData::Models::Ontology.find(acr)
    oss = o.submissions
    assert_equal 1, oss.length
    ont_sub = oss[0]
    ont_sub.load unless ont_sub.loaded?
    assert ont_sub.submissionStatus.parsed?
    ont_sub.classes(:load_attrs => [:prefLabel, :synonym]).each do |c|
      assert (not c.prefLabel.nil?)
      assert_instance_of String, c.prefLabel.value
      if c.resource_id.value.include? "class6"
        #either the RDF label of the synonym
        assert ("rdfs label value" == c.prefLabel.value || "syn for class 6" == c.prefLabel.value)
      end
      if c.resource_id.value.include? "class3"
        assert_equal "class3", c.prefLabel.value
      end
      if c.resource_id.value.include? "class1"
        assert_equal "class 1 literal", c.prefLabel.value
      end
    end
  end

  def test_submission_root_classes
    return if ENV["SKIP_PARSING"]

    acr = "CSTPROPS"
    init_test_ontology_msotest acr
    os = LinkedData::Models::OntologySubmission.where :ontology => { :acronym => acr }, :submissionId => 1
    assert(os.length == 1)
    os = os[0]

    roots = os.roots
    assert_instance_of(Array, roots)
    assert_equal(2, roots.length)
    root_ids = ["http://bioportal.bioontology.org/ontologies/msotes#class1",
      "http://bioportal.bioontology.org/ontologies/msotes#class6" ]
     # class 3 is now subClass of some anonymous thing.
     # "http://bioportal.bioontology.org/ontologies/msotes#class3"]
    roots.each do |r|
      assert(root_ids.include? r.resource_id.value)
      root_ids.delete_at(root_ids.index(r.resource_id.value))
    end
    #I have found them all
    assert(root_ids.length == 0)

    os.ontology.load
    os.ontology.delete
    os.delete
  end

  #ontology with errors
  def test_submission_parse_emo
    return if ENV["SKIP_PARSING"]
    acronym = "EMO-TST"
    name = "EMO Bla"
    ontologyFile = "./test/data/ontology_files/emo_1.1.owl"
    id = 10

    emo = LinkedData::Models::Ontology.find(acronym)
    if not emo.nil?
      sub = emo.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end

    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => acronym, :submissionId => id,})
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id,ontologyFile)
    ont_submision.uploadFilePath = uploadFilePath
    owl, emo, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)
    emo.administeredBy = user
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.hasOntologyLanguage = owl
    ont_submision.ontology = emo
    ont_submision.submissionStatus = status
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)

    sub = LinkedData::Models::OntologySubmission.where ontology: { acronym: acronym }, submissionId: id
    sub = sub[0]
    sub.load unless sub.loaded?
    sub.ontology.load unless sub.ontology.loaded?

    assert_raise LinkedData::Parser::OWLAPIParserException do
      sub.process_submission Logger.new(STDOUT)
    end

    sub = LinkedData::Models::Ontology.find(acronym)
    if not sub.nil?
      sub = sub.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end
  end

  #escaping sequences
  def test_submission_parse_sbo
    return if ENV["SKIP_PARSING"]
    acronym = "SBO-TST"
    name = "SBO Bla"
    ontologyFile = "./test/data/ontology_files/SBO.obo"
    id = 10

    sbo = LinkedData::Models::Ontology.find(acronym)
    if not sbo.nil?
      sub = sbo.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end

    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => acronym, :submissionId => id,})
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id,ontologyFile)
    ont_submision.uploadFilePath = uploadFilePath
    owl, sbo, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)
    sbo.administeredBy = user
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.hasOntologyLanguage = owl
    ont_submision.ontology = sbo
    ont_submision.submissionStatus = status
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)

    sbo = LinkedData::Models::OntologySubmission.where ontology: { acronym: acronym }, submissionId: id
    sbo = sbo[0]
    sbo.load unless sbo.loaded?
    sbo.ontology.load unless sbo.ontology.loaded?
    sbo.process_submission Logger.new(STDOUT)
    assert sbo.submissionStatus.parsed?

    sbo = LinkedData::Models::Ontology.find(acronym)
    if not sbo.nil?
      sub = sbo.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end
  end

  #ontology with import errors
  def test_submission_parse_cno
    return if ENV["SKIP_PARSING"]
    acronym = "CNO-TST"
    name = "CNO Bla"
    ontologyFile = "./test/data/ontology_files/CNO_05.owl"
    id = 10

    emo = LinkedData::Models::Ontology.find(acronym)
    if not emo.nil?
      sub = emo.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end

    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => acronym, :submissionId => id,})
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id,ontologyFile)
    ont_submision.uploadFilePath = uploadFilePath
    owl, emo, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)
    emo.administeredBy = user
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.hasOntologyLanguage = owl
    ont_submision.ontology = emo
    ont_submision.submissionStatus = status
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)

    sub = LinkedData::Models::OntologySubmission.where ontology: { acronym: acronym }, submissionId: id
    sub = sub[0]
    sub.load unless sub.loaded?
    sub.ontology.load unless sub.ontology.loaded?
    sub.process_submission Logger.new(STDOUT)
    assert sub.submissionStatus.parsed?

    assert sub.missingImports.length == 1
    assert sub.missingImports[0] == "http://purl.org/obo/owl/ro_bfo1-1_bridge"

    sub = LinkedData::Models::OntologySubmission.where ontology: { acronym: acronym }, submissionId: id
    sub = sub[0]
    sub.load unless sub.loaded?
    assert sub.missingImports.length == 1
    assert sub.missingImports[0] == "http://purl.org/obo/owl/ro_bfo1-1_bridge"

    sub = LinkedData::Models::Ontology.find(acronym)
    if not sub.nil?
      sub = sub.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end
  end

  #multiple preflables
  def test_submission_parse_aero
    return if ENV["SKIP_PARSING"]
    acronym = "AERO-TST"
    name = "aero Bla"
    ontologyFile = "./test/data/ontology_files/aero.owl"
    id = 10

    aero = LinkedData::Models::Ontology.find(acronym)
    if not aero.nil?
      sub = aero.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end

    ont_submision =  LinkedData::Models::OntologySubmission.new({ :acronym => acronym, :submissionId => id,})
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id,ontologyFile)
    ont_submision.uploadFilePath = uploadFilePath
    owl, aero, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)
    aero.administeredBy = user
    ont_submision.contact = contact
    ont_submision.released = DateTime.now - 4
    ont_submision.prefLabelProperty =  RDF::IRI.new "http://www.w3.org/2000/01/rdf-schema#label"
    ont_submision.synonymProperty = RDF::IRI.new "http://purl.obolibrary.org/obo/IAO_0000118"
    ont_submision.definitionProperty = RDF::IRI.new "http://purl.obolibrary.org/obo/IAO_0000115"
    ont_submision.authorProperty = RDF::IRI.new "http://purl.obolibrary.org/obo/IAO_0000117"
    ont_submision.hasOntologyLanguage = owl
    ont_submision.ontology = aero
    ont_submision.submissionStatus = status
    assert (ont_submision.valid?)
    ont_submision.save
    assert_equal true, ont_submision.exist?(reload=true)

    aero = LinkedData::Models::OntologySubmission.where ontology: { acronym: acronym }, submissionId: id
    aero = aero[0]
    aero.load unless aero.loaded?
    aero.ontology.load unless aero.ontology.loaded?
    aero.process_submission Logger.new(STDOUT)
    assert aero.submissionStatus.parsed?

    aero = LinkedData::Models::Ontology.find(acronym)
    if not aero.nil?
      sub = aero.submissions || []
      sub.each do |s|
        s.load
        s.delete
      end
    end
  end

end

