module LinkedData
  module Parser
    class RepositoryFoldersError < Parser::ParserException
    end
    class InputFileNotFoundError < Parser::ParserException
    end
    class MasterFileMissingException < Parser::ParserException
    end
    class OWLAPICommand
      def initialize(input_file, output_repo, master_file=nil)
        @input_file = input_file
        @output_repo = output_repo
        @master_file = master_file
      end
      
      def setup_environment
        if Utils::FileHelpers.exists_and_file(@output_repo)
          raise RepositoryFoldersError, "Outout repository folder are files in the system `#{@output_repo}`"
        end
        if not File.exist?(@input_file)
          raise InputFileNotFoundError, "#{@input_file} not found."
        end
        if @master_file.nil? and Utils::FileHelpers.zip?(@input_file)
          raise MasterFileMissingException , "Master file not provided and input is zipped archive."
        end
        if not Dir.exist?(@output_repo) 
          begin 
            FileUtils.mkdir_p(@output_repo)
          rescue SystemCallError => e
            raise MkdirException, "Output folder #{@output_repo} folder cannot be created."  
          end
        end
        return File.new(@input_file), Dir.new(@output_repo)
      end

      def parse
        in_file, out_folder = setup_environment
      end
    end
  end
end
