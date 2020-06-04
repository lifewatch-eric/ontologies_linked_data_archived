require 'pry'
require 'rest-client'
require 'json'
require 'optparse'

BACKEND_AG = 'ag'
BACKEND_4STORE = '4store'
GOO_HOST = 'localhost'
AG_USERNAME = 'test'
AG_PASSWORD = 'xyzzy'
AG_PORT = 10035
AG_HOST = "http://#{GOO_HOST}:#{AG_PORT}"
JOB_NAME = 'bioportal'
@options = nil

def main
  @options = parse_options

  if @options[:backend] == BACKEND_AG
    puts "\nUsing AllegroGraph v#{@options[:version]} on port #{AG_PORT}...\n\n"
    pull_cmd = "docker pull franzinc/agraph:v#{@options[:version]}"
    run_cmd = "docker run -d -e AGRAPH_SUPER_USER=#{AG_USERNAME} -e AGRAPH_SUPER_PASSWORD=#{AG_PASSWORD} -p #{AG_PORT}:#{AG_PORT} --shm-size 1g --name agraph-#{@options[:version]}-#{AG_PORT} franzinc/agraph:v#{@options[:version]}"
    system("#{pull_cmd}")
    system("#{run_cmd}")
    sleep(5)
    rest_call("/repositories/#{JOB_NAME}", 'PUT')
    rest_call('/users/anonymous', 'PUT')
    rest_call("/users/anonymous/access?read=true&write=true&repositories=#{JOB_NAME}", 'PUT')
  elsif @options[:backend] == BACKEND_4STORE
    puts "\nUsing 4store...\n"
  end
  test_cmd = 'bundle exec rake test'
  test_cmd << " TEST=\"#{@options[:filename]}\"" unless @options[:filename].empty?
  test_cmd << " TESTOPTS=\"--name=#{@options[:test]}\"" unless @options[:test].empty?
  puts "\n#{test_cmd}\n\n"

  ENV['OVERRIDE_CONNECT_GOO'] = 'true'
  ENV['GOO_HOST'] = GOO_HOST
  ENV['GOO_BACKEND_NAME'] = @options[:backend]

  if @options[:backend] == BACKEND_AG
    ENV['GOO_PORT'] = AG_PORT.to_s
    ENV['GOO_PATH_QUERY'] = '/repositories/bioportal'
    ENV['GOO_PATH_DATA'] = '/repositories/bioportal/statements'
    ENV['GOO_PATH_UPDATE'] = '/repositories/bioportal/statements'
  elsif @options[:backend] == BACKEND_4STORE
    ENV['GOO_PORT'] = 8080.to_s
    ENV['GOO_PATH_QUERY'] = '/sparql/'
    ENV['GOO_PATH_DATA'] = '/data/'
    ENV['GOO_PATH_UPDATE'] = '/update/'
  end

  system("#{test_cmd}")

  if @options[:backend] == BACKEND_AG
    img_name = "agraph-#{@options[:version]}-#{AG_PORT}"
    rm_cmd = "docker rm -f -v #{img_name}"
    puts "\nRemoving Docker Image: #{img_name}\n\n"
    %x(#{rm_cmd})
  end
end

def rest_call(path, method)
  data = {}
  response = RestClient::Request.new(
      :method => method,
      :url => "#{AG_HOST}#{path}",
      :user => AG_USERNAME,
      :password => AG_PASSWORD,
      :headers => { :accept => :json, :content_type => :json }
  ).execute
  data = JSON.parse(response.to_str) if ['POST' 'PUT'].include?(method)
  data
end

def parse_options
  backends = [BACKEND_4STORE, BACKEND_AG]
  options = {
      backend: BACKEND_4STORE,
      version: '',
      filename: '',
      test: ''
  }
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: bundle exec ruby #{File.basename(__FILE__)} [options]"

    opts.on('-b', "--backend [#{BACKEND_4STORE}|#{BACKEND_AG}]", "An optional backend name (default: #{BACKEND_4STORE})") do |bn|
      options[:backend] = bn.strip.downcase if backends.include?(bn.downcase)
    end

    opts.on('-v', '--version VERSION', "Version of AllegroGraph to test against. Required if '#{BACKEND_AG}' is specified as the --backend") do |ver|
      options[:version] = ver.strip.downcase
    end

    opts.on('-f', '--file TEST_FILE_PATH', "An optional path to a test file to be run. Default: all test files") do |f|
      options[:filename] = f.strip
    end

    opts.on('-t', '--test TEST_NAME', "An optional name of the test to be run. Default: all tests") do |test|
      options[:test] = test.strip
    end

    opts.on('-h', '--help', 'Display this screen') do
      puts opts
      exit
    end
  end
  opt_parser.parse!

  if options[:backend] == BACKEND_AG && options[:version].empty?
    puts 'When using AllegroGraph, the version number is required. Run this script with the -h parameter for more information.'
    abort("Aborting...\n")
  end
  options[:test] = '' if options[:filename].empty?
  options
end

main