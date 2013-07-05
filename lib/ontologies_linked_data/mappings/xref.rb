module LinkedData
  module Mappings
    class XREF < LinkedData::Mappings::BatchProcess

      def initialize(ontA,ontB, logger)
        @record = Struct.new(:acronym,:term_id,:xref)

        f = Goo::Filter.new(:xref).bound
        paging = LinkedData::Models::Class.where.filter(f).include(:prefLabel,:xref)
        dumper = lambda { |c,ont| [[ont.acronym, c.id.to_s, c.xref.to_s]]}
        line_parser = lambda { |line| record_from_line(line) }
        is_mapping = lambda { |ra,rb| return ra.xref == rb.xref }
        skip_mapping = lambda { |ra,rb| return (ra.acronym == rb.acronym) ||
                                               (ra.term_id == rb.term_id) }
        sort_field = 3
        super("xref",
              paging,dumper,line_parser,is_mapping,skip_mapping,
              logger,sort_field,ontA, ontB)
      end

      def record_from_line(line)
        line = line.strip
        line_parts = line.split(",")
        r = @record.new
        r.acronym = line_parts.first
        r.term_id = RDF::URI.new(line_parts[1])
        r.xref = line_parts[2]
        return r
      end
    end # XREF

  end # Mappings
end # LinKedData
