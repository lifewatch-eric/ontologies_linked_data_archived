module LinkedData
  module Models
    class OntologySubmission < LinkedData::Models::Base
      model :ontology_submission
      attribute :acronym, :unique => true
      attribute :submissionId, :unique => true, :instance_of =>  { :with => Fixnum }
      attribute :name, :cardinality => { :max => 1, :min => 1 }

      #configurable properties
      attribute :prefLabelProperty, :instance_of =>  { :with => RDF::IRI }, :single_value => true
      attribute :definitionProperty, :instance_of =>  { :with => RDF::IRI }, :single_value  => true
      attribute :synonymProperty, :instance_of =>  { :with => RDF::IRI }, :single_value  => true
      attribute :classType, :instance_of =>  { :with => RDF::IRI }, :single_value  => true
      attribute :hiearchyProperty, :instance_of =>  { :with => RDF::IRI }, :single_value  => true

      #internal values for parsing - not definitive
      attribute :repoPath,  :single_value =>true, :not_nil =>true
      attribute :uploadFileName,  :single_value =>true, :not_nil =>true
      attribute :masterFileName,  :single_value =>true

      #link to ontology
      attribute :ontology, :single_value => true, :not_nil => true, :instance_of => { :with => :ontology }

      attribute :ontologyFormat, :single_value => true, :not_nil => true, :instance_of => { :with => :ontology_format }
      attribute :administeredBy, :not_nil => true, :instance_of => { :with => :user }

      def valid?
        valid_result = super
        return valid_result && self.sanity_check
      end

      def sanity_check
        #if master file points to a zip file
        file_path = File.join(self.repoPath, self.uploadFileName)

        zip = LinkedData::Utils::FileHelpers.zip?(file_path) 
        if not zip and self.masterFileName.nil?
          #unique file
          self.masterFileName = self.uploadFileName
          return true

        elsif zip and self.masterFileName.nil?
          #zip and masterFileName not set. The user has to choose.
          if self.errors[:uploadFileName].nil?
            self.errors[:uploadFileName] = []
          end
          files =  LinkedData::Utils::FileHelpers.files_from_zip(file_path)
          
          #check for duplicated names
          repeated_names =  LinkedData::Utils::FileHelpers.repeated_names_in_file_list(files)
          if repeated_names.length > 0
            names = repeated_names.keys.to_s
            self.errors[:uploadFileName] << "Zip file contains file names (#{names}) in more than one folder." 
            return false
          end

          #error message with options to choose from.
          self.errors[:uploadFileName] << { :message => "Zip file detected, choose the master file.", :options => files }
          return false

        elsif zip and not self.masterFileName.nil?
          #if zip and the user chose a file then we make sure the file is in the list.
          files =  LinkedData::Utils::FileHelpers.files_from_zip(file_path)
          if not files.include? self.masterFileName
            if self.errors[:uploadFileName].nil?
              self.errors[:uploadFileName] = []
              self.errors[:uploadFileName] << { :message => "The selected file `#{self.materFileName}` is not included in the zip file", :options => files }
            end
          end
        end
        return true
      end 
    end
  end
end
