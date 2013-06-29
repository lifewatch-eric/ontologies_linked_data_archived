require 'open3'
require 'csv'

module LinkedData
  module Mappings
    class CUI < LinkedData::Mappings::BatchProcess

      def initialize(ontA,ontB, logger)
        @record_tuple = Struct.new(:record_a,:record_b)
        @record = Struct.new(:acronym,:term_id,:cui)
        super("cui",logger,ontA, ontB)
      end

      def run()
        labels_dumps_file_paths = []
        @ontologies.each do |ont|
         labels_dumps_file_paths << CUI.create_ontology_cuis_dump(ont,logger=@logger)
        end
        ontologies_sorted = @ontologies.sort_by { |ont| ont.acronym }
        ont_first = ontologies_sorted.first
        all_labels_file = File.join([BatchProcess.mappings_ontology_folder(ont_first),
                                     "aggregated_cui_labels_with_#{ontologies_sorted.last.acronym}.txt"])
        sort_command = "cat " + (labels_dumps_file_paths.join " ") + "| sort -t, -k3"
        if $TMP_SORT_FOLDER
          if not Dir.exist?($TMP_SORT_FOLDER)
            FileUtils.mkdir_p($TMP_SORT_FOLDER)
          end
          sort_command += " -T #{$TMP_SORT_FOLDER}"
        end
        sort_command += " > #{all_labels_file}"
        @logger.info("sort_command: #{sort_command}")
        t0 = Time.now
        stdin, stdout, stderr, wait_thr = Open3.popen3(sort_command)
        unless wait_thr.value.success?
          @logger.error("error in sort command pid:#{wait_thr.pid}, exit code #{wait_thr.value}")
          @logger.error("error in sort command pid:#{wait_thr.pid}, err trace #{stderr.read}")
          @logger.error("error in sort command pid:#{wait_thr.pid}, out trace #{stdout.read}")
          raise Exception, "Error in sort command '#{sort_command}'"
        end
        @logger.info("sort success. run in #{Time.now - t0} sec.")
        mapping_pairs = process_sort_results(all_labels_file)
        mapping_pairs.each do |pair|
          id_t_a = LinkedData::Mappings.create_term_mapping([pair.record_a.term_id],
                                    pair.record_a.acronym)
          id_t_b = LinkedData::Mappings.create_term_mapping([pair.record_b.term_id],
                                    pair.record_b.acronym)
          mapping_id = LinkedData::Mappings.create_mapping([id_t_a, id_t_b])
          LinkedData::Mappings.connect_mapping_process(mapping_id, @process)
          #register(mapping_id)
        end
      end

      def record_from_line(line)
        line = line.strip
        line_parts = line.split(",")
        r = @record.new
        r.acronym = line_parts.first
        r.term_id = RDF::URI.new(line_parts[1])
        r.cui = line_parts[2]
        return r
      end

      def process_sort_results(sorted_labels_file)
        record_a = nil
        record_b = nil
        tuples = []
        backlog = []
        File.open(sorted_labels_file,"r").each do |line|
          if record_b && (record_a.cui == record_b.cui)
            backlog << record_b
          else
            backlog = []
          end
          record_b = record_a
          record_a = record_from_line(line)
          if record_a && record_b
            next if record_a.acronym == record_b.acronym
            next if record_a.term_id == record_b.term_id
            if record_a.cui== record_b.cui
              tuples << create_record_tuple(record_a,record_b)
              if backlog.length > 0
                backlog.each do |back_log_tuple|
                  tuples << create_record_tuple(record_a,back_log_tuple)
                end
              end
            end
          end
        end
        return tuples
      end

      def self.create_ontology_cuis_dump(ont,logger=nil)
        ont.bring(submissions: [:submissionId])
        latest_submission = ont.latest_submission

        labels_file = File.join([BatchProcess.mappings_ontology_folder(ont), 
                                 "cui_labels_#{ont.acronym}_#{latest_submission.submissionId}.txt"])
        if $MAPPING_RELOAD_LABELS ||
          !File.exist?(labels_file) || File.size(labels_file) == 0
          t0 = Time.now
          if logger
            logger.info("dumping labels in cui for #{ont.acronym} ...")
          end
          page_i = 1
          f = Goo::Filter.new(:cui).bound 
          paging = LinkedData::Models::Class.where.filter(f)
                                      .in(latest_submission).include(:prefLabel,:cui).page(page_i,2500)

          page = nil
          cui_count = 0
          CSV::open(labels_file,'wb') do |csv|
            begin
              page = paging.all
              page.each do |c|
                csv << [ont.acronym, c.id.to_s, c.cui]
              end
              page_i += 1
              cui_count += 1
              paging.page(page_i)
            end while(page.next?)
          end
          if logger
            logger.info("dumped cui:#{cui_count} "+
                         " for #{ont.acronym} in #{Time.now - t0} sec.")
          end
        end
        return labels_file
      end
    end # cui

  end # Mappings
end # LinKedData
