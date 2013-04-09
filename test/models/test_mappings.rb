require_relative "./test_ontology_common"
require "logger"

class TestMapping < LinkedData::TestOntologyCommon
  def setup
    if LinkedData::Models::Mapping.all.length > 100
      puts "KB with too many mappings to run test. Is this pointing to a TEST KB?"
      raise Exception, "KB with too many mappings to run test. Is this pointing to a TEST KB?"
    end
    LinkedData::Models::Mapping.all do |m|
      m.delete
    end
    ontologies_parse()
  end

  def ontologies_parse()
    submission_parse("MappingOntTest1", "MappingOntTest1", "./test/data/ontology_files/BRO_v3.2.owl", 11)
    submission_parse("MappingOntTest2", "MappingOntTest2", "./test/data/ontology_files/CNO_05.owl", 22)
    submission_parse("MappingOntTest3", "MappingOntTest3", "./test/data/ontology_files/aero.owl", 33)
  end

  def submission_parse( acronym, name, ontologyFile, id)
    return if ENV["SKIP_PARSING"]

    bro = LinkedData::Models::Ontology.find(acronym)
    if not bro.nil?
      sub = bro.submissions || []
      if sub.length > 0
        return if sub[0].submissionStatus.parsed?
      end
      sub.each do |s|
        s.load unless s.loaded?
        s.delete
      end
      bro.delete
    end
    ont_submision =  LinkedData::Models::OntologySubmission.new({ :submissionId => id})
    assert (not ont_submision.valid?)
    assert_equal 6, ont_submision.errors.length
    uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id, ontologyFile)
    ont_submision.uploadFilePath = uploadFilePath
    owl, bro, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED",name)
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

  def get_process(name)
    #just some user
    user = LinkedData::Models::User.all[0]

    #process
    ps = LinkedData::Models::MappingProcess.where({:name => name })
    ps.each do |p| 
      p.delete
    end
    p = LinkedData::Models::MappingProcess.new(:owner => user, :name => name)
    assert p.valid?
    p.save
    ps = LinkedData::Models::MappingProcess.where({:name => name })
    assert ps.length == 1
    return ps[0]
  end

  def test_multiple_mapping()

    process = get_process("LOOMTEST") 

    ont1 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest1" })[0]
    sub1 = ont1.latest_submission
    ont2 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest2" })[0]
    sub2 = ont2.latest_submission
    ont3 = LinkedData::Models::Ontology.where({ :acronym => "MappingOntTest3" })[0]
    sub3 = ont3.latest_submission

    LinkedData::Models::Occurrence.all.each do |occ|
      occ.delete
    end

    
    LinkedData::Models::Mapping.all.each do |occ|
      occ.delete
    end

    occ12 = LinkedData::Models::Occurrence.new()
    occ12.ontologies = [ont1, ont2]
    occ12.process = process
    assert occ12.valid?
    occ12.save

    occ13 = LinkedData::Models::Occurrence.new()
    occ13.ontologies = [ont1, ont3]
    occ13.process = process
    assert occ13.valid?
    occ13.save

    occ23 = LinkedData::Models::Occurrence.new()
    occ23.ontologies = [ont2, ont3]
    occ23.process = process
    assert occ23.valid?
    occ23.save

    ont1_terms = ["http://bioontology.org/ontologies/Activity.owl#Activity",
 "http://bioontology.org/ontologies/Activity.owl#Biospecimen_Management",
 "http://bioontology.org/ontologies/Activity.owl#Community_Engagement",
 "http://bioontology.org/ontologies/Activity.owl#Deprecated_Activity",
 "http://bioontology.org/ontologies/Activity.owl#Gene_Therapy",
 "http://bioontology.org/ontologies/Activity.owl#Health_Services",
 "http://bioontology.org/ontologies/Activity.owl#Heath_Services",
 "http://bioontology.org/ontologies/Activity.owl#IRB",
 "http://bioontology.org/ontologies/Activity.owl#Medical_Device_Development",
 "http://bioontology.org/ontologies/Activity.owl#Novel_Therapeutics",
 "http://bioontology.org/ontologies/Activity.owl#Regulatory_Compliance"]
    ont1_terms.map! { |x| LinkedData::Models::Class.find(RDF::IRI.new(x), submission: sub1) }

    ont2_terms = ["http://purl.obolibrary.org/obo/SBO_0000512",
 "http://purl.obolibrary.org/obo/SBO_0000513",
 "http://purl.obolibrary.org/obo/SBO_0000514",
 "http://purl.obolibrary.org/obo/SBO_0000515",
 "http://purl.obolibrary.org/obo/SBO_0000516",
 "http://purl.obolibrary.org/obo/SBO_0000517",
 "http://purl.obolibrary.org/obo/SBO_0000518",
 "http://purl.obolibrary.org/obo/SBO_0000519",
 "http://purl.obolibrary.org/obo/SBO_0000520",
 "http://purl.obolibrary.org/obo/SBO_0000521",
 "http://purl.obolibrary.org/obo/SBO_0000522"]
    ont2_terms.map! { |x| LinkedData::Models::Class.find(RDF::IRI.new(x), submission: sub2) }
      
      
    ont3_terms = ["http://purl.obolibrary.org/obo/IAO_0000178",
 "http://purl.obolibrary.org/obo/IAO_0000179",
 "http://purl.obolibrary.org/obo/IAO_0000180",
 "http://purl.obolibrary.org/obo/IAO_0000181",
 "http://purl.obolibrary.org/obo/IAO_0000182",
 "http://purl.obolibrary.org/obo/IAO_0000183",
 "http://purl.obolibrary.org/obo/IAO_0000184",
 "http://purl.obolibrary.org/obo/IAO_0000185",
 "http://purl.obolibrary.org/obo/IAO_0000186",
 "http://purl.obolibrary.org/obo/IAO_0000225",
 "http://purl.obolibrary.org/obo/IAO_0000300"]
    ont3_terms.map! { |x| LinkedData::Models::Class.find(RDF::IRI.new(x), submission: sub3) }

    ont1_terms.each_index do |i|
      t1 = ont1_terms[i]
      t2 = ont2_terms[i]
      map = LinkedData::Models::Mapping.new()
      map.terms = [t1,t2]
      map.occurrence = occ12
      assert map.valid?
      map.save
    end

    assert LinkedData::Models::Mapping.all.length == ont1_terms.length

    match = 0
    LinkedData::Models::Mapping.all.each do |map|
      term_ids = map.terms.map { |t| t.resource_id.value }
      ont1_terms.each_index do |i1|
        t1 = ont1_terms[i1]
        if term_ids.include? t1.resource_id.value 
          match += 1
          assert term_ids.include?(ont2_terms[i1].resource_id.value)
        end
      end
    end
    assert match == ont1_terms.length
    assert LinkedData::Models::Occurrence.all.length == 3

    ont2_terms.each_index do |i|
      t2 = ont2_terms[i]
      t3 = ont3_terms[i]
      map = LinkedData::Models::Mapping.new()
      map.terms = [t2,t3]
      map.occurrence = occ23
      assert map.valid?
      map.save
    end

    assert LinkedData::Models::Mapping.all.length == (ont1_terms.length + ont2_terms.length)

    #search for two particular ontologies ont2,ont3
    # how do I search for multiple values of the same attribute 
    occs = LinkedData::Models::Occurrence.where ontologies: [ ont1, ont2 ]
    assert occs.length == 1
    assert occs[0].ontologies.length == 2
    assert (occs[0].ontologies.select { |o| o.name == "MappingOntTest1" }).length == 1
    assert (occs[0].ontologies.select { |o| o.name == "MappingOntTest2" }).length == 1

  end
end
