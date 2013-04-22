module LinkedData
  module Utils
    module Triples
      def self.names
        LinkedData::Utils::Namespaces
      end
      def self.rdf_for_custom_properties(ont_sub)
        triples = []
        triples << "<#{names.meta_prefLabel}> <#{names.rdfs_subPropertyOf}> <#{names.skos_prefLabel}> ."
        unless ont_sub.prefLabelProperty.nil?
          unless ont_sub.prefLabelProperty.value == names.rdfs_label
            triples << "<#{ont_sub.prefLabelProperty.value}> <#{names.rdfs_subPropertyOf}> <#{names.meta_prefLabel}> ."
            triples << "<#{names.skos_prefLabel}> <#{names.rdfs_subPropertyOf}> <#{names.rdfs_label}> ."
          end
        end
        unless ont_sub.definitionProperty.nil?
          unless ont_sub.definitionProperty.value == names.rdfs_label
          triples << "<#{ont_sub.definitionProperty.value}> <#{names.rdfs_subPropertyOf}> <#{names.skos_definition}> ."
          end
        end
        unless ont_sub.synonymProperty.nil?
          unless ont_sub.synonymProperty.value == names.rdfs_label
            triples << "<#{ont_sub.synonymProperty.value}> <#{names.rdfs_subPropertyOf}> <#{names.skos_altLabel}> ."
            triples << "<#{names.skos_altLabel}> <#{names.rdfs_subPropertyOf}> <#{names.rdfs_label}> ."
          end
        end
        unless ont_sub.authorProperty.nil?
          triples << "<#{ont_sub.authorProperty.value}> <#{names.rdfs_subPropertyOf}> <#{names.dc_creator}> ."
        end

        if ont_sub.hasOntologyLanguage.obo?
          #obo syns
          triples << "<#{names.gen_sy}> <#{names.rdfs_subPropertyOf}> <#{names.skos_altLabel}> ."
          triples << "<#{names.obo_sy}> <#{names.rdfs_subPropertyOf}> <#{names.skos_altLabel}> ."
          
          #obo defs
          triples << "<#{names.rdfs_comment}> <#{names.rdfs_subPropertyOf}> <#{names.skos_definition}> ."
          triples << "<#{names.obo_def}> <#{names.rdfs_subPropertyOf}> <#{names.skos_definition}> ."
        end
        return (triples.join "\n")
      end

      def self.label_for_class_triple(class_id,property,label)
        label = label.gsub('\\','\\\\\\\\')
        label = label.gsub('"','\"')
        "<#{class_id.value}> <#{property.value}> \"\"\"#{label}\"\"\"^^<#{names.xsd_string}> ."
      end
    end
  end
end
