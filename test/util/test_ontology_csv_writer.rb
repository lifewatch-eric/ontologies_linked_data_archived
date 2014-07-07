require_relative '../models/test_ontology_common'
require 'csv'

class TestOntologyCSVWriter < LinkedData::TestOntologyCommon

  def setup
    @acronym = 'CSV_TEST_BRO'
    sub_id = 1

    # Directory for storing CSV output.
    @path_to_repo = File.join([LinkedData.settings.repository_folder, @acronym, sub_id.to_s])
    if not Dir.exist? @path_to_repo
      FileUtils.mkdir_p @path_to_repo
    end

    # Create a test ontology submission.
    submission_parse(@acronym, 'CSV TEST BRO', 
                     './test/data/ontology_files/BRO_v3.2.owl', sub_id, 
                     process_rdf: true, index_search: false, run_metrics: false, reasoning: true)
    sub = LinkedData::Models::OntologySubmission.where(ontology: [acronym: @acronym], submissionId: sub_id).include(:version).first

    # Open the CSV writer.
    writer = LinkedData::Utils::OntologyCSVWriter.new
    writer.open(@path_to_repo, @acronym)

    # Write out the CSV.
    page = 1
    size = 2500
    @num_classes = 0
    props_to_include = LinkedData::Models::Class.goo_attrs_to_load() << :parents
    paging = LinkedData::Models::Class.in(sub).include(props_to_include).page(page, size)

    while !page.nil?
      page_classes = paging.page(page, size).all
      
      page_classes.each do |c|
        writer.write_class(c)
      end
      
      @num_classes += page_classes.length
      page = page_classes.next? ? page + 1 : nil
    end

    writer.close
  end

  def get_path_to_csv
    return File.join(@path_to_repo, @acronym + '.csv')
  end

  def test_csv_writer_valid
    assert File.file?(get_path_to_csv)
  end

  def test_csv_writer_row_count
    classes = CSV.read(get_path_to_csv, headers:true)
    assert_equal(true, @num_classes == classes.count)
  end

  def test_csv_writer_content
    class_id = 'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Facility_Core'
    preferred_label = 'Facility Core'
    definition = 'As defined in http://dictionary.reference.com/browse/facility'
    parent_ids = ['http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Material_Resource', 
                  'http://bioontology.org/ontologies/BiomedicalResourceOntology.owl#Service_Resource']

    CSV.open(get_path_to_csv, headers:true) do |c|
      classes = c.each
      classes.select do |row|
        if row['Preferred Label'] == preferred_label
          assert_equal row['Class ID'], class_id
          assert_equal row['Definitions'], definition
          assert_equal row['Parents'], parent_ids.join('|')
          assert_equal row['Obsolete'], 'false'        
        end
      end
    end
  end

end