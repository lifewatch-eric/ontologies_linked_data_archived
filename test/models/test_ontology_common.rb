require_relative "../test_case"

module LinkedData
  class TestOntologyCommon < LinkedData::TestCase
    def submission_dependent_objects(format,acronym,user_name,status_code, name_ont)
      #ontology format
      owl = LinkedData::Models::OntologyFormat.where(:acronym => format).first
      assert_instance_of LinkedData::Models::OntologyFormat, owl

      #user test_linked_models
      user = LinkedData::Models::User.where(:username => user_name).first
      if user.nil?
        user = LinkedData::Models::User.new(:username => user_name, :email => "some@email.org" )
        user.passwordHash = "some random pass hash"
        user.save
      end
      #
      #ontology
      ont = LinkedData::Models::Ontology.where(:acronym => acronym).first
      if ont.nil?
        ont = LinkedData::Models::Ontology.new(:acronym => acronym, :name => name_ont, administeredBy: [user]).save
      end

      #user test_linked_models
      status = LinkedData::Models::SubmissionStatus.where(:code => status_code).first

      # contact
      contact_name = "Peter"
      contact_email = "peter@example.org"
      contact = LinkedData::Models::Contact.where(name: contact_name, email: contact_email).first
      contact = LinkedData::Models::Contact.new(name: contact_name, email: contact_email).save if contact.nil?

      #Submission Status
      return owl, ont, user, status, contact
    end

    def submission_parse( acronym, name, ontologyFile, id)
      return if ENV["SKIP_PARSING"]

      bro = LinkedData::Models::Ontology.find(acronym)
      if not bro.nil?
        sub = bro.submissions || []
        sub.each do |s|
          s.load
          s.delete
        end
      end
      ont_submision =  LinkedData::Models::OntologySubmission.new({ :submissionId => id})
      assert (not ont_submision.valid?)
      assert_equal 6, ont_submision.errors.length
      uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acronym, id, ontologyFile)
      ont_submision.uploadFilePath = uploadFilePath
      owl, bro, user, status, contact = submission_dependent_objects("OWL", acronym, "test_linked_models", "UPLOADED", name)
      ont_submision.contact = [contact]
      ont_submision.released = DateTime.now - 4
      ont_submision.hasOntologyLanguage = owl
      ont_submision.ontology = bro
      ont_submision.submissionStatus = status
      binding.pry if !ont_submision.valid?
      assert (ont_submision.valid?)
      ont_submision.save
      assert_equal true, ont_submision.exist?(reload=true)
      uploaded = LinkedData::Models::SubmissionStatus.find("UPLOADED").include(:submissions).first
      uploded_ontologies = uploaded.submissions
      uploaded_ont = nil
      uploded_ontologies.each do |ont|
        ont.bring(ontology: [:acronym])
        if ont.ontology.acronym == acronym
          uploaded_ont = ont
        end
      end
      assert (not uploaded_ont.nil?)
      uploaded_ont.process_submission Logger.new(STDOUT)
    end

    def init_test_ontology_msotest(acr)
      ont = LinkedData::Models::Ontology.find(acr)
      if not ont.nil?
        sub = ont.submissions || []
        if sub.length > 0
          return if sub[0].submissionStatus.parsed?
        end
        sub.each do |s|
          s.load unless s.loaded?
          s.delete
        end
        ont.delete
      end
      ont_submision =  LinkedData::Models::OntologySubmission.new({ :submissionId => 1 })
      assert (not ont_submision.valid?)
      assert_equal 6, ont_submision.errors.length
      file_path = "./test/data/ontology_files/custom_properties.owl"
      uploadFilePath = LinkedData::Models::OntologySubmission.copy_file_repository(acr, 1, file_path)
      ont_submision.uploadFilePath = uploadFilePath
      owl, ont, user, status, contact = submission_dependent_objects("OWL", acr, "test_linked_models", "UPLOADED", "some ont created by mso for testing")
      ont.administeredBy = user
      ont_submision.contact = contact
      ont_submision.released = DateTime.now - 4
      ont_submision.hasOntologyLanguage = owl
      ont_submision.ontology = ont
      ont_submision.submissionStatus = status
      ont_submision.prefLabelProperty = RDF::IRI.new("http://bioportal.bioontology.org/ontologies/msotes#myPrefLabel")
      ont_submision.synonymProperty = RDF::IRI.new("http://bioportal.bioontology.org/ontologies/msotes#mySynonymLabel")
      ont_submision.definitionProperty = RDF::IRI.new("http://bioportal.bioontology.org/ontologies/msotes#myDefinition")
      ont_submision.authorProperty = RDF::IRI.new("http://bioportal.bioontology.org/ontologies/msotes#myAuthor")
      assert (ont_submision.valid?)
      ont_submision.save
      assert_equal true, ont_submision.exist?(reload=true)
      uploaded = LinkedData::Models::SubmissionStatus.find("UPLOADED")
      uploded_ontologies = uploaded.submissions
      uploaded_ont = nil
      uploded_ontologies.each do |ont|
        ont.load unless ont.loaded?
        ont.ontology.load unless ont.ontology.loaded?
        if ont.ontology.acronym == acr
          uploaded_ont = ont
        end
      end
      assert (not uploaded_ont.nil?)
      if not uploaded_ont.ontology.loaded?
        uploaded_ont.ontology.load
      end
      uploaded_ont.process_submission Logger.new(STDOUT)

      #test to see if custom properties were saved in the graph
      custom_props = [ "http://bioportal.bioontology.org/ontologies/msotes#myPrefLabel",
        "http://bioportal.bioontology.org/ontologies/msotes#myDefinition",
        "http://bioportal.bioontology.org/ontologies/msotes#mySynonymLabel",
        "http://bioportal.bioontology.org/ontologies/msotes#myAuthor"]
      custom_props.each do |p|
        query = <<eos
SELECT * WHERE {
    GRAPH <#{uploaded_ont.resource_id.value}> {
        <#{p}> <http://www.w3.org/2000/01/rdf-schema#subPropertyOf> ?super .
    } }
eos
        count = 0
        Goo.store.query(query).each_solution do |sol|
          if (sol.get(:super).value.include? "skos") || (sol.get(:super).value.include? "elements") ||  (sol.get(:super).value.include? "metadata")
            count += 1
          end
        end
        assert (count > 0)
      end
    end
  end
end

