require "goo"

require_relative "../config/default.rb"
require_relative "ontologies_linked_data/hypermedia/hypermedia"
require_relative "ontologies_linked_data/serializer"
require_relative "ontologies_linked_data/serializers/serializers"
require_relative "ontologies_linked_data/utils/file"
require_relative "ontologies_linked_data/utils/triples"
require_relative "ontologies_linked_data/utils/namespaces"
require_relative "ontologies_linked_data/parser/parser"
require_relative "ontologies_linked_data/monkeypatches/object"
require_relative "ontologies_linked_data/monkeypatches/logging"

# Setup Goo (repo connection and namespaces)
port = $GOO_PORT || 9000
host = $GOO_HOST || "localhost"
begin
  if Goo.store().nil?
    puts ">> Connecting to rdf store #{host}:#{port}"
    Goo.configure do |conf|
      conf[:stores] = [ { :name => :main , :host => host, :port => port,
        :options => { :rules => :NONE} } ]
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
rescue Exception => e
  abort("EXITING: Cannot connect to triplestore")
end

# Require base model
require_relative "ontologies_linked_data/models/base"

# Require all models
project_root = File.dirname(File.absolute_path(__FILE__))
Dir.glob(project_root + '/ontologies_linked_data/models/**/*.rb', &method(:require))
$project_bin = project_root + '/../bin/'

# Sample data generator
require_relative "../test/data/generate_test_data"
