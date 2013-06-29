require 'open3'
require 'csv'

module LinkedData
  module Mappings
    class Loom < LinkedData::Mappings::BatchProcess

      def initialize(ontA,ontB, logger)
        @record_tuple = Struct.new(:record_a,:record_b)
        @record = Struct.new(:acronym,:term_id,:label,:type)
        super("loom",logger,ontA, ontB)
      end

      def run()
        labels_dumps_file_paths = []
        @ontologies.each do |ont|
         labels_dumps_file_paths << Loom.create_ontology_labels_dump(ont,logger=@logger)
        end
        ontologies_sorted = @ontologies.sort_by { |ont| ont.acronym }
        ont_first = ontologies_sorted.first
        all_labels_file = File.join([BatchProcess.mappings_ontology_folder(ont_first),
                                     "aggregated_loom_labels_with_#{ontologies_sorted.last.acronym}.txt"])
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
        r.label = line_parts[2]
        r.type = line_parts[3]
        return r
      end

      def process_sort_results(sorted_labels_file)
        record_a = nil
        record_b = nil
        tuples = []
        backlog = []
        File.open(sorted_labels_file,"r").each do |line|
          if record_b && (record_a.label == record_b.label)
            backlog << record_b
          else
            backlog = []
          end
          record_b = record_a
          record_a = record_from_line(line)
          if record_a && record_b
            next if record_a.acronym == record_b.acronym
            next if record_a.term_id == record_b.term_id
            next if record_a.type == 'sy' && record_b.type == 'sy'
            if record_a.label == record_b.label
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

      def self.transmform_literal(lit)
        res = []
        lit.each_char do |c|
          if (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
            res << c.downcase
          end
        end
        return res.join ''
      end

      def self.create_ontology_labels_dump(ont,logger=nil)
        ont.bring(submissions: [:submissionId])
        latest_submission = ont.latest_submission

        labels_file = File.join([BatchProcess.mappings_ontology_folder(ont), 
                       "loom_labels_#{ont.acronym}_#{latest_submission.submissionId}.txt"])
        if $MAPPING_RELOAD_LABELS ||
          !File.exist?(labels_file) || File.size(labels_file) == 0
          t0 = Time.now
          if logger
            logger.info("dumping labels in loom for #{ont.acronym} ...")
          end
          page_i = 1
          paging = LinkedData::Models::Class.in(latest_submission)
                        .include(:prefLabel,:synonym).page(page_i,2500)
          page = nil
          pref_label_count = 0
          sy_label_count = 0
          CSV::open(labels_file,'wb') do |csv|
            begin
              page = paging.all
              page.each do |c|
                pref = transmform_literal(c.prefLabel)
                if pref.length > 2
                  csv << [ont.acronym,c.id.to_s, pref , 'pref']
                  pref_label_count += 1
                end
                c.synonym.each do |sy|
                  sy_t = transmform_literal(sy)
                  if sy_t.length > 2
                    csv << [ont.acronym,c.id.to_s,sy_t, 'sy']
                    sy_label_count += 1
                  end
                end
              end
              page_i += 1
              paging.page(page_i)
            end while(page.next?)
          end
          if logger
            logger.info("dumped pref:#{pref_label_count} "+
                         "sy:#{sy_label_count} for #{ont.acronym} in #{Time.now - t0} sec.")
          end
        end
        return labels_file
      end
    end # Loom

  end # Mappings
end # LinKedData
