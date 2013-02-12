# Start simplecov if this is a coverage task
if ENV["COVERAGE"].eql?("true")
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
    add_filter "app.rb"
    add_filter "init.rb"
    add_filter "/config/"
  end
end

require_relative "../lib/ontologies_linked_data"
require "test/unit"
require "webmock/minitest"
WebMock.allow_net_connect!

module LinkedData
  class TestCase < Test::Unit::TestCase

    def submission_dependent_objects(format,acronym,user_name,status_code)
      #ontology format
      LinkedData::Models::OntologyFormat.init
      owl = LinkedData::Models::OntologyFormat.where(:acronym => format)[0]
      assert_instance_of LinkedData::Models::OntologyFormat, owl

      #ontology
      LinkedData::Models::OntologyFormat.init
      ont = LinkedData::Models::Ontology.where(:acronym => acronym)
      LinkedData::Models::OntologyFormat.init
      assert(ont.length < 2)
      if ont.length == 0
        ont = LinkedData::Models::Ontology.new({:acronym => acronym})
      else
        ont = ont[0]
      end

      #user test_linked_models
      users = LinkedData::Models::User.where(:username => user_name)
      assert(users.length < 2)
      if users.length == 0
        user = LinkedData::Models::User.new({:username => user_name})
      else
        user = users[0]
      end

          #user test_linked_models
      LinkedData::Models::SubmissionStatus.init
      status = LinkedData::Models::SubmissionStatus.where(:code => status_code)
      assert(status.length < 2)
      if status.length == 0
        status = LinkedData::Models::SubmissionStatus.new({:code => status_code})
      else
        status = status[0]
      end

      #Submission Status
      return owl, ont, user, status
    end

    def teardown
      delete_ontologies_and_submissions
    end

    ##
    # Creates a set of Ontology and OntologySubmission objects and stores them in the triplestore
    # @param [Hash] options the options to create ontologies with
    # @option options [Fixnum] :ont_count Number of ontologies to create
    # @option options [Fixnum] :submission_count How many submissions each ontology should have (acts as max number when random submission count is used)
    # @option options [TrueClass, FalseClass] :random_submission_count Use a random number of submissions between 1 and :submission_count
    def create_ontologies_and_submissions(options = {})
      delete_ontologies_and_submissions

      ont_count = options[:ont_count] || 5
      submission_count = options[:submission_count] || 5
      random_submission_count = options[:random_submission_count].nil? ? true : options[:random_submission_count]

      u = LinkedData::Models::User.new(username: "tim", email: "tim@example.org", password: "password")
      u.save unless u.exist? || !u.valid?

      contact_name = "Sheila"
      contact_email = "sheila@example.org"
      contact = LinkedData::Models::Contact.where(name: contact_name, email: contact_email)
      contact = LinkedData::Models::Contact.new(name: contact_name, email: contact_email) if contact.empty?

      of = LinkedData::Models::OntologyFormat.find("OWL")
      if of.nil?
        of = LinkedData::Models::OntologyFormat.new(acronym: "OWL")
        assert of.valid?
        of.save
      end

      LinkedData::Models::SubmissionStatus.init

      ont_acronyms = []
      ontologies = []
      ont_count.to_i.times do |count|
        acronym = "TST-ONT-#{count}"
        ont_acronyms << acronym

        o = LinkedData::Models::Ontology.new({
          acronym: acronym,
          name: "Test Ontology ##{count}",
          administeredBy: u
        })

        o.save
        ontologies << o

        # Random submissions (between 1 and max)
        max = random_submission_count ? (1..submission_count.to_i).to_a.shuffle.first : submission_count
        max.times do
          os = LinkedData::Models::OntologySubmission.new({
            ontology: o,
            hasOntologyLanguage: of,
            summaryOnly: true,
            submissionStatus: LinkedData::Models::SubmissionStatus.find("UPLOADED"),
            submissionId: o.next_submission_id,
            contact: contact,
            released: DateTime.now - 3
          })
          binding.pry if !os.valid?
          os.save
        end
      end

      # Get ontology objects if empty
      if ontologies.empty?
        ont_acronyms.each do |ont_id|
          ontologies << LinkedData::Models::Ontology.find(ont_id)
        end
      end

      return ont_count, ont_acronyms, ontologies
    end

    ##
    # Delete all ontologies and their submissions. This will look for all ontologies starting with TST-ONT- and ending in a Fixnum
    def delete_ontologies_and_submissions
      ont = LinkedData::Models::Ontology.find("TST-ONT-0")
      count = 0
      while ont
        ont.delete unless ont.nil?
        ont = LinkedData::Models::Ontology.find("TST-ONT-#{count+1}")
      end

      u = LinkedData::Models::User.find("tim")
      u.delete unless u.nil?

      of = LinkedData::Models::OntologyFormat.find("OWL")
      of.delete unless of.nil?
    end

    def delete_goo_models(gooModelArray)
      gooModelArray.each do |m|
        m.load
        m.delete
        assert_equal(false, m.exist?(reload=true), "Failed to delete a goo model.")
      end
    end

    # Test the 'creator' attribute of a GOO model class
    # @note This method name cannot begin with 'test_' or it will be called as a test
    # @param [LinkedData::Models] model_class a GOO model class, e.g. LinkedData::Models::Project
    # @param [LinkedData::Models::User] user a valid instance of LinkedData::Models::User
    def model_creator_test(model_class, user)
      # TODO: if the input argument is an instance, use the .class.new methods?
      m = model_class.new
      assert_equal(false, m.valid?, "#{m} .valid? returned true, it was expected to be invalid.")
      m.creator = "test name" # string is not valid
      assert_equal(false, m.valid?, "#{m} .valid? returned true, it was expected to be invalid.")
      assert_equal(false, m.errors[:creator].nil?) # We expect there to be errors on creator
      assert_instance_of(LinkedData::Models::User, user, "#{user} is not an instance of LinkedData::Models::User")
      assert_equal(true, user.valid?, "#{user} is not a valid instance of LinkedData::Models::User")
      m.creator = user  # LinkedData::Models::User instance is valid, but other attributes may generate errors.
      assert_equal(false, m.valid?, "#{m} .valid? returned true, it was expected to be invalid.")
      assert_equal(true, m.errors[:creator].nil?) # We expect there to be no errors on creator, there may be others.
    end

    # Test the 'created' attribute of a GOO model
    # @note This method name cannot begin with 'test_' or it will be called as a test
    # @param [LinkedData::Models::Base] m a valid model instance with a 'created' attribute (without a value).
    def model_created_test(m)
      assert_equal(true, m.kind_of?(LinkedData::Models::Base), "Expected kind_of?(LinkedData::Models::Base).")
      assert_equal(true, m.valid?, "Expected valid model: #{m.errors}")
      m.save if m.valid?
      # The default value is auto-generated (during save), it should be OK.
      assert_instance_of(DateTime, m.created, "The 'created' attribute is not a DateTime instance.")
      assert_equal(true, m.errors[:created].nil?, "#{m.errors}")
      m.created = "this string should fail"
      assert (not m.valid?)
      assert_equal(false, m.errors[:created].nil?, "#{m.errors}")
      # The value should be an XSD date time.
      m.created = DateTime.new
      assert m.valid?
      assert_instance_of(DateTime, m.created)
      assert_equal(true, m.errors[:created].nil?, "#{m.errors}")
    end

    # Test the save and delete methods on a GOO model
    # @param [LinkedData::Models::Base] m a valid model instance that can be saved and deleted
    def model_lifecycle_test(m)
      assert_equal(true, m.kind_of?(LinkedData::Models::Base), "Expected kind_of?(LinkedData::Models::Base).")
      assert_equal(true, m.valid?, "Expected valid model: #{m.errors}")
      assert_equal(false, m.exist?(reload=true), "Given model is already saved, expected one that is not.")
      m.save
      assert_equal(true, m.exist?(reload=true), "Failed to save model.")
      m.delete
      assert_equal(false, m.exist?(reload=true), "Failed to delete model.")
    end

  end
end
