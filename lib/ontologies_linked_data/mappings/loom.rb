module LinkedData
  module Mappings
    class Loom < LinkedData::Mappings::BatchProcess

      def initialize(ontA,ontB, logger)
        @record = Struct.new(:acronym,:term_id,:label,:type)

        paging = LinkedData::Models::Class.where.include(:prefLabel,:synonym)
        dumper = lambda { |c,ont| dump_class_labels(c,ont) }
        line_parser = lambda { |line| record_from_line(line) }
        is_mapping = lambda { |ra,rb| return ra.label == rb.label && 
                                             ((ra.type != rb.type) || 
                                              (ra.type == rb.type && ra.type == 'pref')) }
        skip_mapping = lambda { |ra,rb| return (ra.acronym == rb.acronym) ||
                                               (ra.term_id == rb.term_id) }
        sort_field = 3
        super("loom",
              paging,dumper,line_parser,is_mapping,skip_mapping,
              logger,sort_field,ontA, ontB)
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

      def transmform_literal(lit)
        res = []
        lit.each_char do |c|
          if (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
            res << c.downcase
          end
        end
        return res.join ''
      end

      def dump_class_labels(c,ont)
        labels = []
        pref = transmform_literal(c.prefLabel)
        if pref.length > 2
          labels << [ont.acronym,c.id.to_s, pref , 'pref']
        end
        c.synonym.each do |sy|
          sy_t = transmform_literal(sy)
          if sy_t.length > 2
            labels << [ont.acronym,c.id.to_s,sy_t, 'sy']
          end
        end
        return labels
      end

    end # Loom

  end # Mappings
end # LinKedData
