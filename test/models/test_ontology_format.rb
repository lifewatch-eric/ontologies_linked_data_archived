require_relative "../test_case"

class TestOntologyFormat < LinkedData::TestCase
  def setup
    @acronyms = ["OBO", "OWL"]
  end

  def teardown
    ofs = LinkedData::Models::OntologyFormat.all
    ofs.each do |of|
      of.load
      of.delete
    end
  end
  
  def test_formats
    teardown
    @acronyms.each do |acr|
      of =  LinkedData::Models::OntologyFormat.new( { :acronym => acr } )
      of.save
    end
    @acronyms.each do |acr|
      list =  LinkedData::Models::OntologyFormat.where( :acronym => acr )
      assert_equal 1, list.length
      assert_instance_of LinkedData::Models::OntologyFormat, list[0]
      list[0].load
      assert_equal acr, list[0].acronym
    end
  end

  def test_init
     teardown
     assert_equal 0, LinkedData::Models::OntologyFormat.all.length
     LinkedData::Models::OntologyFormat.init @acronyms
     assert_equal 2, LinkedData::Models::OntologyFormat.all.length
  end

end
