module LinkedData
  module Mappings
    class Loom < LinkedData::Mappings::BatchProcess
      def initialize(ontA,ontB)
        super("loom",ontA, ontB)
      end

      def self.transmform_literal(lit)
        res = []
        lit.each do |c|
          if (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
            res << c.downcase
          end
        end
        return res.join ''
      end

      def self.dump_ontology_labels(ont)
        ont.bring(submissions: [:submissionId])
        latest_submission = ont.latest_submission

        labels_file = File.join([mappings_ontology_folder(ont), 
                                 "loom_labels_#{ont.acronym}_#{latest_submission.submissionId}.txt"])
        if File.exist?(labels_file)
          return labels_file
        else
          page_i = 1
          paging = LinkedData::Models::Class.in(latest_submission).include(:prefLabel,:synonym).page(page_i,2500)
          page = nil
          output_labels = File.open(labels_file, 'wb')
          CSV::Writer.generate(outfile) do |csv|
            begin
              page = paging.all
              page.each do |c|
                pref = transmform_literal(c.prefLabel)
                if pref.length > 2
                  csv << [ont.acronym,c.id.to_s, pref , 'pref']
                end
                c.synonym do |sy|
                  sy_t = transmform_literal(c.sy)
                  if sy_t.length > 2
                    csv << [ont.acronym,c.id.to_s,sy_t, 'sy']
                  end
                end
              end
              page_i += 1
              paging.page(page_i)
            end while(page.next?)
          end
          output_labels.close()
        end
      end
    end
  end
end
