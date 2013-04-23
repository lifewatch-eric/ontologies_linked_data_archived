require 'goo'
require 'ostruct'

module LinkedData
  extend self
  attr_reader :settings

  @settings = OpenStruct.new
  @settings_run = false

  def config(&block)
    return if @settings_run
    @settings_run = true

    overide_connect_goo = false

    yield @settings, overide_connect_goo if block_given?

    # Set defaults
    @settings.goo_port          ||= 9000
    @settings.goo_host          ||= "localhost"
    @settings.search_server_url ||= "http://localhost:8983/solr"
    @settings.repository_folder ||= "./test/data/ontology_files/repo"
    @settings.rest_url_prefix   ||= "http://data.bioontology.org/"
    @settings.enable_security   ||= false
    @settings.redis_host        ||= "localhost"
    @settings.redis_port        ||= 6379

    connect_goo unless overide_connect_goo
  end

  ##
  # Connect to goo by configuring the store and search server
  def connect_goo(host = nil, port = nil, search_server_url = nil)
    port              ||= @settings.goo_port
    host              ||= @settings.goo_host
    search_server_url ||= @settings.search_server_url

    begin
      puts ">> Connecting to rdf store #{host}:#{port} and search server at #{search_server_url}"
      ::Goo.configure do |conf|
        conf[:stores] = [ { :name => :main , :host => host, :port => port, :options => { :rules => :NONE} } ]
        conf[:search_conf] = { :search_server => search_server_url }
      end
    rescue Exception => e
      abort("EXITING: Cannot connect to triplestore and/or search server:\n  #{e}")
    end
  end

  ##
  # Configure ontologies_linked_data namespaces
  # We do this at initial runtime because goo needs namespaces for its DSL
  def goo_namespaces
    ::Goo.configure do |conf|
      conf[:namespaces] = {
        :metadata => "http://data.bioontology.org/metadata/",
        :omv => "http://omv.ontoware.org/2005/05/ontology#",
        :skos => "http://www.w3.org/2004/02/skos/core#",
        :owl => "http://www.w3.org/2002/07/owl#",
        :rdfs => "http://www.w3.org/2000/01/rdf-schema#",
        :default => :metadata
      }
    end
  end
  self.goo_namespaces

end
