require_relative "../test_case"
require_relative "../../lib/ontologies_linked_data/purl/purl_client"
require 'rack'

class TestOntology < LinkedData::TestCase

  def self.before_suite
    @@port = Random.rand(55000..65535) # http://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers#Dynamic.2C_private_or_ephemeral_ports
    @@thread = Thread.new do
      Rack::Server.start(
        app: lambda do |e|
          [200, {'Content-Type' => 'text/plain'}, ['test file']]
        end,
        Port: @@port
      )
    end
  end

  def self.after_suite
    Thread.kill(@@thread)
  end

  def setup
    @acronym = "ONT-FOR-TEST"
    @name = "TestOntology TEST"
    _delete_objects

    @user = LinkedData::Models::User.find("tim").first ||
               LinkedData::Models::User.new(username: "tim", email: "tim@example.org", password: "password").save

    @of = LinkedData::Models::OntologyFormat.find("OWL").first ||
            LinkedData::Models::OntologyFormat.new(acronym: "OWL").save

    cname = "Jeff Baines"
    cemail = "jeff@example.org"
    @contact = LinkedData::Models::Contact.where(name: cname, email: cemail).to_a[0]
    @contact = LinkedData::Models::Contact.new(name: cname, email: cemail).save if @contact.nil?
  end

  def teardown
    super
    _delete_objects
    delete_ontologies_and_submissions
  end

  def _create_ontology_with_submissions
    _delete_objects

    o = LinkedData::Models::Ontology.new({
      acronym: @acronym,
      administeredBy: [@user],
      name: @name
    })
    o.save

    os = LinkedData::Models::OntologySubmission.new({
      ontology: o,
      hasOntologyLanguage: @of,
      pullLocation: RDF::IRI.new("http://localhost:#{@@port}/"),
      submissionId: o.next_submission_id,
      contact: [@contact],
      released: DateTime.now - 5
    })
    os.save
  end

  def _delete_objects
    o = LinkedData::Models::Ontology.find(@acronym).first
    o.delete unless o.nil?
  end

  def test_invalid_acronym
    o = LinkedData::Models::Ontology.new
    o.acronym = "-1234"  # must start with A-Z
    o.valid?
    assert o.errors[:acronym] && o.errors[:acronym][:acronym_value_validator]
    o = LinkedData::Models::Ontology.new
    o.acronym = "abc1234"  # must start with A-Z, no lower case allowed
    o.valid?
    assert o.errors[:acronym] && o.errors[:acronym][:acronym_value_validator]
    o = LinkedData::Models::Ontology.new
    o.acronym = "1234ABC"  # must start with A-Z
    o.valid?
    assert o.errors[:acronym] && o.errors[:acronym][:acronym_value_validator]
    o = LinkedData::Models::Ontology.new
    o.acronym = "ABCDEFGHIJKLMNOPQ"  # no more than 16 chars
    o.valid?
    assert o.errors[:acronym] && o.errors[:acronym][:acronym_value_validator]
    o = LinkedData::Models::Ontology.new
    o.acronym = "A"  # must begin with at least 1 char in A-Z
    o.valid?
    assert !o.errors[:acronym]
    o.acronym = "ABCDEFGHIJKLMNOP"  # up to 16 chars OK
    o.valid?
    assert !o.errors[:acronym]
  end

  def test_valid_ontology
    o = LinkedData::Models::Ontology.new
    assert (not o.valid?)

    o.acronym = @acronym
    o.name = @name

    u = LinkedData::Models::User.new(username: "tim")
    o.administeredBy = [@user]

    assert o.valid?
  end


  def test_ontology_delete
    count, acronyms, ontologies = create_ontologies_and_submissions(ont_count: 2, submission_count: 1, process_submission: true)
    u, of, contact = ontology_objects()
    o1 = ontologies[0]
    o2 = ontologies[1]

    n = LinkedData::Models::Note.new({
      creator: u,
      relatedOntology: [o1]
    })
    assert n.valid?
    n.save()
    assert_equal true, n.exist?(reload=true)

    review_params = {
        :creator => u,
        :created => DateTime.new,
        :body => "This is a test review.",
        :ontologyReviewed => o1,
        :usabilityRating => 0,
        :coverageRating => 0,
        :qualityRating => 0,
        :formalityRating => 0,
        :correctnessRating => 0,
        :documentationRating => 0
    }

    r = LinkedData::Models::Review.new(review_params)
    r.save()
    assert_equal true, r.exist?(reload=true)

    o1.delete()
    assert_equal false, n.exist?(reload=true)
    assert_equal false, r.exist?(reload=true)
    assert_equal false, o1.exist?(reload=true)
  end

  def test_ontology_lifecycle
    o = LinkedData::Models::Ontology.new({
      acronym: @acronym,
      name: @name,
      administeredBy: [@user]
    })

    # Create
    assert_equal false, o.exist?(reload=true)
    o.save
    assert_equal true, o.exist?(reload=true)

    # Delete
    o.delete
    assert_equal false, o.exist?(reload=true)
  end

  def test_next_submission_id
    _create_ontology_with_submissions
    ss = LinkedData::Models::Ontology.find(@acronym).to_a[0]
    assert(ss.next_submission_id == 2)
  end

  def test_ontology_deletes_submissions
    _create_ontology_with_submissions
    ont = LinkedData::Models::Ontology.find(@acronym).first
    ont.delete
    submissions = LinkedData::Models::OntologySubmission.where(ontology: [acronym: @acronym])
    assert submissions.empty?
  end

  def test_latest_any_submission
    count, acronyms, ont = create_ontologies_and_submissions(ont_count: 1, submission_count: 3)
    ont = ont.first
    latest = ont.latest_submission(status: :any)
    assert_equal 3, latest.submissionId
  end

  def test_purl_creation
    return unless LinkedData.settings.enable_purl
    count, acronyms, ont = create_ontologies_and_submissions(ont_count: 3, submission_count: 1)
    purl_client = LinkedData::Purl::Client.new

    acronyms.each do |acronym|
      assert purl_client.purl_exists(acronym)
    end
  end

  def test_latest_parsed_submission
    count, acronyms, ont = create_ontologies_and_submissions(ont_count: 1, submission_count: 3)
    ont = ont.first
    ont.bring(submissions: [:submissionId])
    sub = ont.submissions[1]
    sub.bring(*LinkedData::Models::OntologySubmission.attributes)
    sub.set_ready
    sub.save
    latest = ont.latest_submission
    assert_equal 2, latest.submissionId
  end

  def test_submission_retrieval
    count, acronyms, ont = create_ontologies_and_submissions(ont_count: 1, submission_count: 3)
    middle_submission = ont.first.submission(2)
    assert_equal 2, middle_submission.submissionId
  end

  def test_all_submission_retrieval
    count, acronyms, ont = create_ontologies_and_submissions(ont_count: 1, submission_count: 3)
    ont = ont.first
    ont.bring(:submissions)
    all_submissions = ont.submissions
    assert_equal 3, all_submissions.length
  end

  def test_duplicate_contacts
    _create_ontology_with_submissions
    ont = LinkedData::Models::Ontology.find(@acronym).first
    ont.bring(submissions: [:contact])
    sub = ont.submissions.first
    assert sub.contact.length == 1
  end

end
