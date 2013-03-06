$GOO_PORT = 9000 unless $GOO_PORT
$GOO_HOST = "localhost" unless $GOO_HOST

$REPOSITORY_FOLDER = "./test/data/ontology_files/repo"

$REST_URL_PREFIX = "http://data.bioontology.org"

# Settings in this file can be overridden in the custom.rb (warnings may happen)
custom = File.expand_path('../custom.rb', __FILE__)
require_relative "custom.rb" if File.exists?(custom)