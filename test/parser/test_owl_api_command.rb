require_relative "../test_case"

class TestOWLApi < LinkedData::TestCase

  def test_command_owl_api_single_file
    output_repo =  "test/data/ontology_files/repo/bro/10/output"
    input_file = "test/data/ontology_files/BRO_v3.2.owl"
    owlapi = LinkedData::Parser::OWLAPICommand.new(input_file,output_repo,nil)
    owlapi.parse 
    assert(File.exist?(output_repo))
    assert(File.exist?(input_file))
  end

  def test_command_KO_output
    output_repo =  "/var/log/xxxxx"
    input_file = "test/data/ontology_files/"
    owlapi = LinkedData::Parser::OWLAPICommand.new(input_file,output_repo,nil)
    begin
      owlapi.parse 
      assert(false)
    rescue LinkedData::Parser::ParserException => e
      assert(e.kind_of? LinkedData::Parser::MkdirException)
    end
  end
  def test_command_KO_input
    output_repo =  "/var/log/xxxxx"
    input_file = "test/data/ontology_files/aaaa"
    owlapi = LinkedData::Parser::OWLAPICommand.new(input_file,output_repo,nil)
    begin
      owlapi.parse 
      assert(false)
    rescue LinkedData::Parser::ParserException => e
      assert(e.kind_of? LinkedData::Parser::InputFileNotFoundError)
    end
  end

  def test_command_KO_master
    output_repo =  "/var/log/xxxxx"
    input_file = "test/data/ontology_files/fma_3.1_owl_file_v3.1.zip"
    owlapi = LinkedData::Parser::OWLAPICommand.new(input_file,output_repo,nil)
    begin
      owlapi.parse 
      assert(false)
    rescue LinkedData::Parser::ParserException => e
      assert(e.kind_of? LinkedData::Parser::MasterFileMissingException)
    end
  end

end
