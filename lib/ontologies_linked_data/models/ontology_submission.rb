require 'net/ftp'
require 'net/http'
require 'uri'
require 'open-uri'
require 'cgi'
require 'benchmark'

module LinkedData
  module Models

    class OntologySubmission < LinkedData::Models::Base
      model :ontology_submission, name_with: lambda { |s| submission_id_generator(s) }
      attribute :submissionId, enforce: [:integer, :existence]

      # Configurable properties for processing
      attribute :prefLabelProperty, enforce: [:uri]
      attribute :definitionProperty, enforce: [:uri]
      attribute :synonymProperty, enforce: [:uri]
      attribute :authorProperty, enforce: [:uri]
      attribute :classType, enforce: [:uri]
      attribute :hierarchyProperty, enforce: [:uri]
      attribute :obsoleteProperty, enforce: [:uri]
      attribute :obsoleteParent, enforce: [:uri]

      # Ontology metadata
      attribute :hasOntologyLanguage, namespace: :omv, enforce: [:existence, :ontology_format]
      attribute :homepage
      attribute :publication
      attribute :uri, namespace: :omv
      attribute :naturalLanguage, namespace: :omv
      attribute :documentation, namespace: :omv
      attribute :version, namespace: :omv
      attribute :creationDate, namespace: :omv, enforce: [:date_time], default: lambda { |record| DateTime.now }
      attribute :description, namespace: :omv
      attribute :status, namespace: :omv
      attribute :contact, enforce: [:existence, :contact, :list]
      attribute :released, enforce: [:date_time, :existence]

      # Internal values for parsing - not definitive
      attribute :uploadFilePath
      attribute :masterFileName
      attribute :summaryOnly
      attribute :submissionStatus, enforce: [:submission_status, :existence] 
      attribute :missingImports, enforce: [:list]

      # URI for pulling ontology
      attribute :pullLocation, enforce: [:uri]

      # Link to ontology
      attribute :ontology, enforce: [:existence, :ontology]

      # Hypermedia settings
      embed :contact, :ontology
      embed_values :submissionStatus => [:code], :hasOntologyLanguage => [:acronym]
      serialize_default :contact, :ontology, :hasOntologyLanguage, :released, :creationDate, :homepage,
                        :publication, :documentation, :version, :description, :status, :submissionId

      def self.submission_id_generator(ss)
        binding.pry if ss.ontology.nil?
        if !ss.ontology.loaded_attributes.include?(:acronym) 
          ss.ontology.bring(:acronym)
        end
        if ss.ontology.acronym.nil?
          raise ArgumentError, "Submission cannot be saved if ontology does not have acronym"
        end
        return RDF::URI.new(
          # TODO: Change self.namespace to LinkedData.settings.rest_uri_prefix
          "#{(self.namespace.to_s)}ontologies/#{CGI.escape(ss.ontology.acronym.to_s)}/submissions/#{ss.submissionId.to_s}"
        )
      end

      def self.copy_file_repository(acronym, submissionId, src, filename = nil)
        path_to_repo = File.join([LinkedData.settings.repository_folder, acronym.to_s, submissionId.to_s])
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
        sc = self.sanity_check
        return valid_result && sc
      end

      def sanity_check
        self.bring(:summaryOnly) if self.bring?(:summaryOnly)
        self.bring(:uploadFilePath) if self.bring?(:uploadFilePath)
        self.bring(:pullLocation) if self.bring?(:pullLocation)
        self.bring(:masterFileName) if self.bring?(:masterFileName)
        if self.summaryOnly
          return true
        elsif self.uploadFilePath.nil? && self.pullLocation.nil?
          self.errors[:uploadFilePath] = ["In non-summary only submissions a data file or url must be provided."]
          return false
        elsif self.pullLocation
          self.errors[:pullLocation] = ["File at #{self.pullLocation.to_s} does not exist"]
          return remote_file_exists?(self.pullLocation.to_s)
        end

        zip = LinkedData::Utils::FileHelpers.zip?(self.uploadFilePath)
        files =  LinkedData::Utils::FileHelpers.files_from_zip(self.uploadFilePath) if zip
        if not zip and self.masterFileName.nil?
          return true
        elsif zip and files.length == 1
          self.masterFileName = files.first
          return true
        elsif zip and self.masterFileName.nil?
          #zip and masterFileName not set. The user has to choose.
          if self.errors[:uploadFilePath].nil?
            self.errors[:uploadFilePath] = []
          end

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
                :message => "The selected file `#{self.masterFileName}` is not included in the zip file",
                :options => files }
            end
          end
        end
        return true
      end

      def data_folder
        return File.join(LinkedData.settings.repository_folder, self.ontology.acronym.to_s, self.submissionId.to_s)
      end

      def zip_folder
        return File.join([self.data_folder, "unzipped"])
      end

      def process_submission(logger)

        self.bring_remaining
        self.ontology.bring_remaining

        if not self.valid?
          error = "Submission is not valid, it cannot be processed. Check errors"
          logger.info(error)
          logger.flush
          raise ArgumentError, error
        end

        if not self.uploadFilePath
          error = "Submission is missing an ontology file, cannot parse"
          logger.info(error)
          logger.flush
          raise ArgumentError, error
        end

        logger.info("Starting parse for #{self.ontology.acronym}/submissions/#{self.submissionId}")
        logger.flush

        zip = LinkedData::Utils::FileHelpers.zip?(self.uploadFilePath)
        zip_dst = nil
        if zip
          zip_dst = self.zip_folder
          if Dir.exist? zip_dst
            FileUtils.rm_r [zip_dst]
          end
          FileUtils.mkdir_p zip_dst
          extracted = LinkedData::Utils::FileHelpers.unzip(self.uploadFilePath, zip_dst)

          # Set master file name automatically if there is only one file
          if extracted.length == 1 && self.masterFileName.nil?
            self.masterFileName = extracted.first.name
            self.save
          end

          logger.info("Files extracted from zip #{extracted}")
          logger.flush
        end
        LinkedData::Parser.logger = logger

        if self.hasOntologyLanguage.umls?
          file_name = zip ? File.join(File.expand_path(self.data_folder.to_s), self.masterFileName) : self.uploadFilePath.to_s
          triples_file_path = File.expand_path(file_name)
          logger.info("Using UMLS turtle file, skipping OWLAPI parse")
          logger.flush
          delete_and_append(triples_file_path, logger, SparqlRd::Utils::MimeType.turtle)
        else
          input_data = zip_dst || self.uploadFilePath
          labels_file = File.join(File.dirname(input_data.to_s),"labels.ttl")
          owlapi = LinkedData::Parser::OWLAPICommand.new(File.expand_path(input_data.to_s),File.expand_path(self.data_folder.to_s),self.masterFileName)
          triples_file_path, missing_imports = owlapi.parse
          if missing_imports
            missing_imports.each do |imp|
              logger.info("OWL_IMPORT_MISSING: #{imp}")
            end
          end
          logger.flush
          delete_and_append(triples_file_path, logger)

          missing_labels_generation(logger, labels_file)
          logger.flush
        end

        #index this ontology
        index(logger)

        rdf_status = SubmissionStatus.find("RDF").first
        self.submissionStatus = rdf_status

        if missing_imports && missing_imports.length > 0
          self.missingImports = missing_imports
        else
          self.missingImports = nil
        end

        self.save
        logger.info("Submission status updated to RDF")
        logger.flush
      end

      def index(logger, optimize = true)
        page = 1
        size = 2500

        count_classes = 0
        time = Benchmark.realtime do
          self.ontology.unindex()
          logger.info("Indexing ontology: #{self.ontology.acronym}...")


          paging = LinkedData::Models::Class.in(self).include(:unmapped)
                                  .page(page,size)
          begin #per page
            page_classes = paging.page(page,size).all
            page_classes.each do |c|
              c.map_attributes
            end
            count_classes += page_classes.length
            LinkedData::Models::Class.indexBatch(page_classes)
            page = page_classes.next_page
          end while !page.nil?
          LinkedData::Models::Class.indexCommit()
        end
        logger.info("Completed indexing ontology: #{self.ontology.acronym} in #{time} sec. #{count_classes} classes.")

        if optimize
          logger.info("Optimizing index...")
          time = Benchmark.realtime do
            LinkedData::Models::Class.indexOptimize()
          end
          logger.info("Completed optimizing index in #{time} sec.")
        end
      end

      # Override delete to add removal from the search index
      #TODO: revise this with a better process
      def delete(in_update=false, remove_index=true)
        super(in_update)
        self.ontology.unindex()

        if remove_index
          # need to re-index the previous submission (if exists)
          prev_sub = self.ontology.latest_submission()

          if prev_sub
            prev_sub.index(LinkedData::Parser.logger || $stderr)
          end
        end
      end

      def missing_labels_generation(logger,save_in_file)
        property_triples = LinkedData::Utils::Triples.rdf_for_custom_properties(self)
        result = Goo.sparql_data_client.append_triples(
                      self.id,
                      property_triples,
                      mime_type="application/x-turtle")
        count_classes = 0
        t0 = Time.now
        page = 1
        size = 2500
        t1 = Time.now
        fsave = File.open(save_in_file,"w")
        fsave.write(property_triples)
        paging = LinkedData::Models::Class.in(self).include(:prefLabel, :synonym, :label).page(page,size)
        begin #per page
          label_triples = []
          page_classes = paging.page(page,size).all
          logger.info(
            "#{page_classes.length} in page #{page} classes for #{self.id.to_ntriples} (#{t1 - t0} sec)." +
            " Total pages #{page_classes.total_pages}.")
          logger.flush
          page_classes.each do |c|
            if c.prefLabel.nil?
              rdfs_labels = c.label
              rdfs_labels = [rdfs_labels] if rdfs_labels and not (rdfs_labels.instance_of?Array)
              label = nil
              if rdfs_labels && rdfs_labels.length > 0
                label = rdfs_labels[0]
              else
                label = LinkedData::Utils::Triples.last_iri_fragment c.id.to_s
              end
              label_triples << LinkedData::Utils::Triples.label_for_class_triple(c.id,
                                                     Goo.vocabulary(:metadata_def)[:prefLabel],label)
            end
            count_classes += 1
          end
          if (label_triples.length > 0)
            logger.info("Asserting #{label_triples.length} labels in #{self.id.to_ntriples}")
            logger.flush
            label_triples = label_triples.join "\n"
            fsave.write(label_triples)
            t0 = Time.now
            result = Goo.sparql_data_client.append_triples(
                      self.id,
                      label_triples,
                      mime_type="application/x-turtle")
            t1 = Time.now
            logger.info("Labels asserted in #{t1 - t0} sec.")
            logger.flush
          else
            logger.info("No labels generated in page #{page_classes.total_pages}.")
            logger.flush
          end
          page = page_classes.next_page
        end while !page.nil?
        logger.info("end missing_labels_generation traversed #{count_classes} classes")
        logger.info("Saved generated labels in #{save_in_file}")
        fsave.close()
        logger.flush
      end

      def classes(*args)
        args = [{}] if args.nil? || args.length == 0
        args[0] = args[0].merge({ :submission => self })
        clss = LinkedData::Models::Class.where(*args)
        clss.select! { |c| !c.resource_id.bnode? }
        return clss
      end

      def roots
        classes = LinkedData::Models::Class.where(submission: self, parents: :unbound,
                                                  load_attrs: [:prefLabel, :definition, :synonym, :deprecated])
        roots = []
        classes.each do |c|
          next if c.resource_id.bnode?
          roots << c if (c.attributes[:deprecated].nil?) || (c.attributes[:deprecated] == false)
        end
        return roots
      end

      def download_and_store_ontology_file
        file, filename = download_ontology_file
        file_location = self.class.copy_file_repository(self.ontology.acronym, self.submissionId, file, filename)
        self.uploadFilePath = file_location
        return file, filename
      end

      def remote_file_exists?(url)
        begin
          url = URI.parse(url)
          if url.kind_of?(URI::FTP)
            check = check_ftp_file(url)
          else
            check = check_http_file(url)
          end
        rescue Exception => e
          check = false
        end
        check
      end

      private

      def delete_and_append(triples_file_path, logger, mime_type = nil)
        Goo.sparql_data_client.delete_graph(self.id)
        Goo.sparql_data_client.put_triples(self.id, triples_file_path, mime_type)
        logger.info("Triples #{triples_file_path} appended in #{self.id.to_ntriples}")
        logger.flush
      end

      def download_ontology_file
        file = open(self.pullLocation.value, :read_timeout => nil)
        if file.meta && file.meta["content-disposition"]
          cd = file.meta["content-disposition"].match(/filename=\"(.*)\"/)
          filename = cd.nil? ? nil : cd[1]
        end
        filename = LinkedData::Utils::Namespaces.last_iri_fragment(self.pullLocation.value) if filename.nil?
        return file, filename
      end

      def check_http_file(url)
        session = Net::HTTP.new(url.host, url.port)
        session.use_ssl = true if url.port == 443
        session.start do |http|
          response_valid = http.head(url.request_uri).code.to_i < 400
          return response_valid
        end
      end

      def check_ftp_file(uri)
        ftp = Net::FTP.new(uri.host, uri.user, uri.password)
        ftp.login
        begin
          file_exists = ftp.size(uri.path) > 0
        rescue Exception => e
          # Check using another method
          path = uri.path.split("/")
          filename = path.pop
          path = path.join("/")
          ftp.chdir(path)
          files = ftp.dir
          # Dumb check, just see if the filename is somewhere in the list
          files.each { |file| return true if file.include?(filename) }
        end
        file_exists
      end

    end
  end
end
