require 'open3'

module LinkedData
  module Diff

    class RepositoryFoldersError < Diff::DiffException
    end
    class InputFileNotFoundError < Diff::DiffException
    end
    class DiffFileNotGeneratedException < Diff::DiffException
    end

    class BubastisDiffCommand

      #Usage:
      #java -jar bubastis.jar parameters:
      #(required)  -1 location of ontology 1 (note this is a URI so if it's a local file you
      #                need to specify this with file:/c/:file_name.owl, otherwise it will
      #                attempt to read the location from the web)
      #(required)  -2 location_of_ontology_2 (note this is also a URI )
      #(optional)  -t location of output file to send results, default is to console
      #(optional)  -s produce a summary version of results (short version), default is long version
      #
      #Examples:
      #Loading two files locally and outputting results to console:
      #java -jar bubastis.jar -1 "file:H://obi_nov_08.owl" -2 "file:H://obi_jan_09.owl"
      #
      #Loading two files locally and outputting results to text file in summary format:
      #java -jar bubastis.jar -1 "file:H://obi_nov_08.owl" -2 "file:H://obi_jan_09.owl" -t "H://OBIdiff.txt" -s

      def initialize(input_fileA, input_fileB)
        @bubastis_jar_path = $project_bin + "bubastis.jar"
        @input_fileA = input_fileA
        @input_fileB = input_fileB
        @output_repo = File.expand_path(@input_fileA).gsub(File.basename(@input_fileA),'')
        @file_diff_path = nil
      end

      def setup_environment
        if @input_fileA.nil? or (not File.exist?(@input_fileA))
          raise InputFileNotFoundError, "#{@input_fileA} not found."
        end
        if @input_fileB.nil? or (not File.exist?(@input_fileB))
          raise InputFileNotFoundError, "#{@input_fileB} not found."
        end
        if @output_repo.nil? or Utils::FileHelpers.exists_and_file(@output_repo)
          raise RepositoryFoldersError, "Output repository folder are files in the system `#{@output_repo}`"
        end
        if (not Dir.exist?(@output_repo))
          begin
            FileUtils.mkdir_p(@output_repo)
          rescue SystemCallError => e
            raise MkdirException, "Output folder #{@output_repo} folder cannot be created."
          end
        end
      end

      def call_bubastis_java_cmd
        options = []
        if not @input_fileA.nil?
          uri = "file://#{@input_fileA}"
          options << "-1 #{Shellwords.escape(uri)}"
        end
        if not @input_fileB.nil?
          uri = "file://#{@input_fileB}"
          options << "-2 #{Shellwords.escape(uri)}"
        end
        if not @output_repo.nil?
          # TODO: Create more informative file name than 'diff.xml'?  (May require more work to maintain integrity.)
          # Create output file 'diff.xml' in the repo for @input_fileA.
          @file_diff_path = File.join(@output_repo, 'diff.xml')
          options << "-t #{Shellwords.escape(@file_diff_path)}"
        end
        if options.length == 0
          raise ArgumentError, "Cannot call Bubastis diff command without options."
        end
        errors_log = File.join([@output_repo, "bubastis_diff_errors.log"])
        File.delete errors_log if File.exist? errors_log
        java_cmd = "java -DentityExpansionLimit=1500000 -Xmx5120M -jar #{@bubastis_jar_path} #{options.join(' ')}"
        Diff.logger.info("Java call [#{java_cmd}]")
        stdout,stderr,status = Open3.capture3(java_cmd)
        if not status.success?
          Diff.logger.error("Bubastis diff error")
          Diff.logger.error(stderr)
          Diff.logger.error(stdout)
          raise Diff::BubastisDiffException, "Bubastis java command exited with #{status.exitstatus}. Check diff logs."
        else
          Diff.logger.info("Bubastis diff finished OK.")
          Diff.logger.info(stderr)
          Diff.logger.info(stdout)
        end
        if not File.exist?(@file_diff_path)
          raise Diff::BubastisDiffException, "Bubastis diff command exited with #{status.exitstatus}. " +\
          "Output file #{@file_diff_path} cannot be found."
        else
          Diff.logger.info("Output size #{File.stat(@file_diff_path).size} in `#{@file_diff_path}`")
        end
        return @file_diff_path
      end

      def file_diff_path
        @file_diff_path
      end

      def diff
        setup_environment
        call_bubastis_java_cmd
        if @file_diff_path.nil?
          raise DiffFileNotGeneratedException, "Diff file nil"
        elsif not File.exist?(@file_diff_path)
          raise DiffFileNotGeneratedException, "Diff file not found in #{@file_diff_path}"
        end
        return @file_diff_path
      end
    end
  end
end
