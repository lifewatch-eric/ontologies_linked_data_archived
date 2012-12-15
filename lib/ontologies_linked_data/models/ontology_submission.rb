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
      attribute :status, :instance_of =>  { :with => :submission_status }, :single_value  => true, :not_nil => true
      attribute :summaryOnly, :single_value  => true

      #internal values for parsing - not definitive
      attribute :uploadFilePath,  :single_value =>true, :not_nil =>true
      attribute :masterFileName,  :single_value =>true


      #link to ontology
      attribute :ontology, :single_value => true, :not_nil => true, :instance_of => { :with => :ontology }

      attribute :ontologyFormat, :single_value => true, :not_nil => true, :instance_of => { :with => :ontology_format }
      attribute :administeredBy, :not_nil => true, :instance_of => { :with => :user }

      def self.copy_file_repository(acronym, submissionId, src, filename = nil)
        path_to_repo = File.join([$REPOSITORY_FOLDER, acronym, submissionId.to_s])
        name = filename || File.basename(File.new(src).path)
        if not Dir.exist? path_to_repo
          FileUtils.mkdir_p path_to_repo
        end
        dst = File.join([path_to_repo, name])
        FileUtils.copy(src, dst)
        if not File.exist? dst
          raise Exception, "Unable to copy #{src} to #{dst}"
        end
        return dst
      end

      def valid?
        valid_result = super
        return valid_result && self.sanity_check
      end

      def filename
      end

      def sanity_check
        if self.summaryOnly
          return true
        end

        zip = LinkedData::Utils::FileHelpers.zip?(self.uploadFilePath) 
        if not zip and self.masterFileName.nil?
          #unique file
          self.masterFileName = self.uploadFilePath
          return true

        elsif zip and self.masterFileName.nil?
          #zip and masterFileName not set. The user has to choose.
          if self.errors[:uploadFilePath].nil?
            self.errors[:uploadFilePath] = []
          end
          files =  LinkedData::Utils::FileHelpers.files_from_zip(self.uploadFilePath)
          
          #check for duplicated names
          repeated_names =  LinkedData::Utils::FileHelpers.repeated_names_in_file_list(files)
          if repeated_names.length > 0
            names = repeated_names.keys.to_s
            self.errors[:uploadFilePath] << 
            "Zip file contains file names (#{names}) in more than one folder." 
            return false
          end

          #error message with options to choose from.
          self.errors[:uploadFilePath] << { 
            :message => "Zip file detected, choose the master file.", :options => files }
          return false

        elsif zip and not self.masterFileName.nil?
          #if zip and the user chose a file then we make sure the file is in the list.
          files =  LinkedData::Utils::FileHelpers.files_from_zip(self.uploadFilePath)
          if not files.include? self.masterFileName
            if self.errors[:uploadFilePath].nil?
              self.errors[:uploadFilePath] = []
              self.errors[:uploadFilePath] << { 
                :message => "The selected file `#{self.materFileName}` is not included in the zip file", 
                :options => files }
            end
          end
        end
        return true
      end 

      def data_folder
        return File.join($REPOSITORY_FOLDER, self.ontology.acronym, self.submissionId)
      end

      def process_submission(logger)
        if not self.loaded?
          self.load
          if not self.ontology.loaded?
            self.ontology.load
          end
        end
        input_file = File.join([$REPOSITORY_FOLDER, self.uploadFilePath])
        LinkedData::Parser.logger =  Logger.new(STDOUT)
        owlapi = LinkedData::Parser::OWLAPICommand.new(input_file,self.data_folder,self.masterFileName)
        owlapi.parse 
      end
    end
  end
end
