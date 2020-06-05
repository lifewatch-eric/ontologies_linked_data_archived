require 'pry'
require 'rest-client'
require 'json'
require 'optparse'

BACKEND_AG = 'ag'
BACKEND_4STORE = '4store'
GOO_HOST = 'localhost'
AG_USERNAME = 'test'
AG_PASSWORD = 'xyzzy'
DEF_AG_PORT = 10035
DEF_4STORE_PORT = 9000
JOB_NAME = 'bioportal'
DEF_VERSION = 'latest'
@options = nil

def main
  @options = parse_options

  if @options[:backend] == BACKEND_AG
    @options[:port] = DEF_AG_PORT if @options[:port] <= 0
    puts "\nUsing AllegroGraph #{@options[:version]} on port #{@options[:port]}...\n\n"
    pull_cmd = "docker pull franzinc/agraph:#{@options[:version]}"
    run_cmd = "docker run -d -e AGRAPH_SUPER_USER=#{AG_USERNAME} -e AGRAPH_SUPER_PASSWORD=#{AG_PASSWORD} -p #{@options[:port]}:#{@options[:port]} --shm-size 1g --name #{@options[:backend]}-#{@options[:version]}-#{@options[:port]} franzinc/agraph:#{@options[:version]}"
    system("#{pull_cmd}")
    system("#{run_cmd}")
    sleep(5)
    ag_rest_call("/repositories/#{JOB_NAME}", 'PUT')
    ag_rest_call('/users/anonymous', 'PUT')
    ag_rest_call("/users/anonymous/access?read=true&write=true&repositories=#{JOB_NAME}", 'PUT')
  elsif @options[:backend] == BACKEND_4STORE
    @options[:port] = DEF_4STORE_PORT if @options[:port] <= 0
    puts "\nUsing 4store #{@options[:version]} on port #{@options[:port]}...\n\n"
    pull_cmd = "docker pull bde2020/4store:#{@options[:version]}"
    run_cmd = "docker run -d -p #{@options[:port]}:#{@options[:port]} --shm-size 1g --name #{@options[:backend]}-#{@options[:version]}-#{@options[:port]} bde2020/4store:#{@options[:version]}"
    exec_cmd1 = "docker exec #{@options[:backend]}-#{@options[:version]}-#{@options[:port]} 4s-backend-setup --segments 4 demo"
    exec_cmd2 = "docker exec #{@options[:backend]}-#{@options[:version]}-#{@options[:port]} 4s-admin start-stores demo"
    exec_cmd3 = "docker exec #{@options[:backend]}-#{@options[:version]}-#{@options[:port]} 4s-httpd -s-1 -p#{@options[:port]} demo"
    system("#{pull_cmd}")
    system("#{run_cmd}")
    system("#{exec_cmd1}")
    system("#{exec_cmd2}")
    sleep(5)
    system("#{exec_cmd3}")
    sleep(1)
  end
  test_cmd = 'bundle exec rake test'
  test_cmd << " TEST=\"#{@options[:filename]}\"" unless @options[:filename].empty?
  test_cmd << ' TESTOPTS="-v"'
  test_cmd.gsub!(/"$/, " --name=#{@options[:test]}\"") unless @options[:test].empty?
  puts "\n#{test_cmd}\n\n"

  begin
    ENV['OVERRIDE_CONNECT_GOO'] = 'true'
    ENV['GOO_HOST'] = GOO_HOST
    ENV['GOO_PORT'] = @options[:port].to_s
    ENV['GOO_BACKEND_NAME'] = @options[:backend]

    if @options[:backend] == BACKEND_AG
      ENV['GOO_PATH_QUERY'] = '/repositories/bioportal'
      ENV['GOO_PATH_DATA'] = '/repositories/bioportal/statements'
      ENV['GOO_PATH_UPDATE'] = '/repositories/bioportal/statements'
    elsif @options[:backend] == BACKEND_4STORE
      ENV['GOO_PATH_QUERY'] = '/sparql/'
      ENV['GOO_PATH_DATA'] = '/data/'
      ENV['GOO_PATH_UPDATE'] = '/update/'
    end
    system("#{test_cmd}")
  rescue StandardError => e
    msg = "Failed test run with exception:\n\n#{e.class}: #{e.message}\n"
    puts msg
    puts e.backtrace
  end

  img_name = "#{@options[:backend]}-#{@options[:version]}-#{@options[:port]}"
  rm_cmd = "docker rm -f -v #{img_name}"
  puts "\nRemoving Docker Image: #{img_name}\n"
  %x(#{rm_cmd})
end

def ag_rest_call(path, method)
  data = {}
  response = RestClient::Request.new(
      :method => method,
      :url => "http://#{GOO_HOST}:#{@options[:port]}#{path}",
      :user => AG_USERNAME,
      :password => AG_PASSWORD,
      :headers => { :accept => :json, :content_type => :json }
  ).execute
  data = JSON.parse(response.to_str) if ['get', 'post'].include?(method.downcase)
  data
end

def parse_options
  backends = [BACKEND_4STORE, BACKEND_AG]
  options = {
      backend: BACKEND_4STORE,
      version: DEF_VERSION,
      filename: '',
      test: '',
      port: -1
  }
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: bundle exec ruby #{File.basename(__FILE__)} [options]"

    opts.on('-b', "--backend [#{BACKEND_4STORE}|#{BACKEND_AG}]", "An optional backend name. Default: #{BACKEND_4STORE}") do |bn|
      options[:backend] = bn.strip.downcase if backends.include?(bn.downcase)
    end

    opts.on('-v', '--version VERSION', "An optional version of the server to test against. Default: '#{DEF_VERSION}'\n\t\t\t\t\s\s\s\s\sMust be a valid image tag published on repositories:\n\t\t\t\t\thttps://hub.docker.com/r/bde2020/4store/tags for #{BACKEND_4STORE}\n\t\t\t\t\thttps://hub.docker.com/r/franzinc/agraph/tags for #{BACKEND_AG}") do |ver|
      options[:version] = ver.strip.downcase
    end

    opts.on('-p', '--port PORT', "An optional port number of the server to test against. Default: #{DEF_4STORE_PORT} for #{BACKEND_4STORE}, #{DEF_AG_PORT} for #{BACKEND_AG}\n\t\t\t\t\s\s\s\s\sMust be a valid integer value") do |port|
      options[:port] = port.strip.to_i
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

  if options[:port] == 0
    puts 'The port number must be a valid integer. Run this script with the -h parameter for more information.'
    abort("Aborting...\n")
  end
  options[:test] = '' if options[:filename].empty?
  options
end

main