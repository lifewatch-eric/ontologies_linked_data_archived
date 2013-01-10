require_relative "../test_case"
require 'pry'

class TestOntology < LinkedData::TestCase
  def setup
    @acronym = "SNOMED-TST"
    @name = "SNOMED-CT TEST"
  end

  def teardown
    o = LinkedData::Models::Ontology.find(@acronym)
    o.delete unless o.nil?
  end

  def _create_ontology_with_submissions
    _delete_objects

    u = LinkedData::Models::User.new(username: "tim")
    u.save

    of = LinkedData::Models::OntologyFormat.new(acronym: "OWL")
    of.save

    o = LinkedData::Models::Ontology.new({
      acronym: @acronym,
      name: @name,
      ontologyFormat: "OWL",
      administeredBy: "tim",
    })
    o.save

    os = LinkedData::Models::OntologySubmission.new({
      acronym: @acronym,
      ontology: o,
      ontologyFormat: of,
      administeredBy: u,
      pullLocation: RDF::IRI.new("http://example.com"),
      status: LinkedData::Models::SubmissionStatus.new(:code => "UPLOADED"),
      submissionId: o.next_submission_id
    })
    os.save
  end

  def _delete_objects
    u = LinkedData::Models::User.find("tim")
    u.delete unless u.nil?

    of = LinkedData::Models::OntologyFormat.find("OWL")
    of.delete unless of.nil?

    ss = LinkedData::Models::SubmissionStatus.find("UPLOADED")
    ss.delete unless ss.nil?

    o = LinkedData::Models::Ontology.find(@acronym)
    o.delete unless o.nil?
  end

  def test_valid_ontology
    o = LinkedData::Models::Ontology.new
    assert (not o.valid?)

    o.acronym = @acronym
    o.name = @name
    assert o.valid?
  end

  def test_ontology_lifecycle
    o = LinkedData::Models::Ontology.new({
      acronym: @acronym,
      name: @name
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
    assert LinkedData::Models::Ontology.find(@acronym).next_submission_id == 2
  end

  def test_ontology_deletes_submissions
    _create_ontology_with_submissions
    ont = LinkedData::Models::Ontology.find(@acronym)
    ont.delete
    submissions = LinkedData::Models::OntologySubmission.where(acronym: @acronym)
    assert submissions.empty?
  end

end
