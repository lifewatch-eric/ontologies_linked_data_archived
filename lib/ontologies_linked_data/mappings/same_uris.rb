module LinkedData
  module Mappings
    class SameURI < LinkedData::Mappings::BatchProcess

      def initialize(ontA,ontB, logger)
        @record = Struct.new(:acronym,:term_id,:cui)

        paging = LinkedData::Models::Class.where.include(:prefLabel)
        dumper = lambda { |c,ont| [[ont.acronym, c.id.to_s]]}
        line_parser = lambda { |line| record_from_line(line) }
        is_mapping = lambda { |ra,rb| return ra.term_id == rb.term_id }
        skip_mapping = lambda { |ra,rb| return (ra.acronym == rb.acronym) }
        sort_field = 2
        super("same_uris",
              paging,dumper,line_parser,is_mapping,skip_mapping,
              logger,sort_field,ontA, ontB)
      end

      def record_from_line(line)
        line = line.strip
        line_parts = line.split(",")
        r = @record.new
        r.acronym = line_parts.first
        r.term_id = RDF::URI.new(line_parts[1])
        return r
      end
    end

  end # Mappings
end # LinKedData
