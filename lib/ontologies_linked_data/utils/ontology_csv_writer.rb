require 'csv'
require 'zlib'
require_relative '../../ontologies_linked_data'

module LinkedData
  module Utils
    class OntologyCSVWriter

      def open(path, ont_acronym)
        file = File.new(File.join(path, ont_acronym + '.gz'), 'w')
        gz = Zlib::GzipWriter.new(file)
        @csv = CSV.new(gz, headers: true, return_headers: true, write_headers: true)
        
        # Would have preferred to simply use 'ID' for the first header value.
        # However, if the first two characters of a CSV file are 'ID', opening
        # the file with Excel for Mac displays an error message:
        # 'Excel has detected that <your-file-name>.csv is a SYLK file, but cannot load it.'
        # Link to issue report at Microsoft Support: http://support.microsoft.com/kb/215591/EN-US.
        @csv << ["Class ID","Preferred Label","Synonyms","Definitions","Obsolete","CUI","Semantic Types","Parents"]
      end

      def write_class(ont_class)
        row = CSV::Row.new([], [], false)

        # ID
        row << ont_class.id

        # Preferred label
        row << ont_class.prefLabel

        # Synonyms
        synonyms = ont_class.synonym
        synonyms.empty? ? row << nil : row << synonyms.join('|')

        # Definitions
        definitions = ont_class.definition
        definitions.empty? ? row << nil : row << definitions.join('|')

        # Obsolete
        row << ont_class.obsolete

        # CUI
        cuis = ont_class.cui
        cuis.empty? ? row << nil : row << cuis.join('|')

        # Semantic types
        semantic_types = ont_class.semanticType
        semantic_types.empty? ? row << nil : row << semantic_types.join('|')

        # Parents
        parents = ont_class.parents
        parents.empty? ? row << nil : row << get_parent_ids(parents)

        @csv << row
      end

      def get_parent_ids(parents)
        parent_ids = []
        parents.each do |parent|
          parent_ids << parent.id
        end
        return parent_ids.join('|')
      end

      def close
        @csv.close
      end

    end
  end
end