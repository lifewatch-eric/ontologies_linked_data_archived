# -*- encoding: utf-8 -*-
# stub: ontologies_linked_data 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "ontologies_linked_data".freeze
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Paul R Alexander".freeze]
  s.date = "2018-02-21"
  s.description = "Models and serializers for ontologies and related artifacts backed by 4store".freeze
  s.email = ["palexander@stanford.edu".freeze]
  s.executables = ["bubastis.jar".freeze, "bubastis_readme.txt".freeze, "owlapi-wrapper-1.3.3.jar".freeze]
  s.files = [".gitignore".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/bubastis.jar".freeze, "bin/bubastis_readme.txt".freeze, "bin/owlapi-wrapper-1.3.3.jar".freeze, "config/config.rb.sample".freeze, "config/solr/property_search/enumsconfig.xml".freeze, "config/solr/property_search/mapping-ISOLatin1Accent.txt".freeze, "config/solr/property_search/schema.xml".freeze, "config/solr/property_search/solrconfig.xml".freeze, "config/solr/solr.xml".freeze, "config/solr/term_search/enumsconfig.xml".freeze, "config/solr/term_search/mapping-ISOLatin1Accent.txt".freeze, "config/solr/term_search/schema.xml".freeze, "config/solr/term_search/solrconfig.xml".freeze, "lib/ontologies_linked_data.rb".freeze, "lib/ontologies_linked_data/config/config.rb".freeze, "lib/ontologies_linked_data/diff/bubastis_diff.rb".freeze, "lib/ontologies_linked_data/diff/diff.rb".freeze, "lib/ontologies_linked_data/http_cache/cacheable_resource.rb".freeze, "lib/ontologies_linked_data/hypermedia/hypermedia.rb".freeze, "lib/ontologies_linked_data/hypermedia/link.rb".freeze, "lib/ontologies_linked_data/hypermedia/resource.rb".freeze, "lib/ontologies_linked_data/mappings/mappings.rb".freeze, "lib/ontologies_linked_data/media_types.rb".freeze, "lib/ontologies_linked_data/metrics/metrics.rb".freeze, "lib/ontologies_linked_data/models/base.rb".freeze, "lib/ontologies_linked_data/models/category.rb".freeze, "lib/ontologies_linked_data/models/class.rb".freeze, "lib/ontologies_linked_data/models/contact.rb".freeze, "lib/ontologies_linked_data/models/group.rb".freeze, "lib/ontologies_linked_data/models/instance.rb".freeze, "lib/ontologies_linked_data/models/mappings/mapping.rb".freeze, "lib/ontologies_linked_data/models/metric.rb".freeze, "lib/ontologies_linked_data/models/notes/note.rb".freeze, "lib/ontologies_linked_data/models/notes/proposal.rb".freeze, "lib/ontologies_linked_data/models/notes/proposal_type.rb".freeze, "lib/ontologies_linked_data/models/notes/reply.rb".freeze, "lib/ontologies_linked_data/models/ontology.rb".freeze, "lib/ontologies_linked_data/models/ontology_format.rb".freeze, "lib/ontologies_linked_data/models/ontology_submission.rb".freeze, "lib/ontologies_linked_data/models/ontology_type.rb".freeze, "lib/ontologies_linked_data/models/page.rb".freeze, "lib/ontologies_linked_data/models/project.rb".freeze, "lib/ontologies_linked_data/models/properties/annotation_property.rb".freeze, "lib/ontologies_linked_data/models/properties/datatype_property.rb".freeze, "lib/ontologies_linked_data/models/properties/object_property.rb".freeze, "lib/ontologies_linked_data/models/properties/ontology_property.rb".freeze, "lib/ontologies_linked_data/models/provisional_class.rb".freeze, "lib/ontologies_linked_data/models/provisional_relation.rb".freeze, "lib/ontologies_linked_data/models/review.rb".freeze, "lib/ontologies_linked_data/models/slice.rb".freeze, "lib/ontologies_linked_data/models/submission_status.rb".freeze, "lib/ontologies_linked_data/models/users/authentication.rb".freeze, "lib/ontologies_linked_data/models/users/role.rb".freeze, "lib/ontologies_linked_data/models/users/subscription.rb".freeze, "lib/ontologies_linked_data/models/users/user.rb".freeze, "lib/ontologies_linked_data/monkeypatches/class.rb".freeze, "lib/ontologies_linked_data/monkeypatches/logging.rb".freeze, "lib/ontologies_linked_data/monkeypatches/object.rb".freeze, "lib/ontologies_linked_data/parser/owlapi.rb".freeze, "lib/ontologies_linked_data/parser/parser.rb".freeze, "lib/ontologies_linked_data/purl/purl_client.rb".freeze, "lib/ontologies_linked_data/sample_data/ontology.rb".freeze, "lib/ontologies_linked_data/sample_data/sample_data.rb".freeze, "lib/ontologies_linked_data/security/access_control.rb".freeze, "lib/ontologies_linked_data/security/access_denied_middleware.rb".freeze, "lib/ontologies_linked_data/security/authorization.rb".freeze, "lib/ontologies_linked_data/serializer.rb".freeze, "lib/ontologies_linked_data/serializers/html.rb".freeze, "lib/ontologies_linked_data/serializers/json.rb".freeze, "lib/ontologies_linked_data/serializers/jsonp.rb".freeze, "lib/ontologies_linked_data/serializers/serializers.rb".freeze, "lib/ontologies_linked_data/serializers/xml.rb".freeze, "lib/ontologies_linked_data/utils/file.rb".freeze, "lib/ontologies_linked_data/utils/multi_logger.rb".freeze, "lib/ontologies_linked_data/utils/notifications.rb".freeze, "lib/ontologies_linked_data/utils/ontology_csv_writer.rb".freeze, "lib/ontologies_linked_data/utils/triples.rb".freeze, "lib/ontologies_linked_data/version.rb".freeze, "ontologies_linked_data.gemspec".freeze, "platform.sh".freeze, "test/console.rb".freeze, "test/data/destroy_test_data.rb".freeze, "test/data/generate_test_data.rb".freeze, "test/data/ontology_files/BRO_for_csv.owl".freeze, "test/data/ontology_files/BRO_v3.1.owl".freeze, "test/data/ontology_files/BRO_v3.2.1_v3.2.1.owl".freeze, "test/data/ontology_files/BRO_v3.2.owl".freeze, "test/data/ontology_files/BRO_v3.3.owl".freeze, "test/data/ontology_files/BRO_v3.4.owl".freeze, "test/data/ontology_files/BRO_v3.5.owl".freeze, "test/data/ontology_files/CNO_05.owl".freeze, "test/data/ontology_files/CellLine_OWL_BioPortal_v1.0.owl".freeze, "test/data/ontology_files/CogPO12142010.owl".freeze, "test/data/ontology_files/OntoMA.1.1_vVersion_1.1_Date__11-2011.OWL".freeze, "test/data/ontology_files/SBO.obo".freeze, "test/data/ontology_files/SDO.zip".freeze, "test/data/ontology_files/XCTontologyvtemp2_vvtemp2.zip".freeze, "test/data/ontology_files/aero.owl".freeze, "test/data/ontology_files/cdao_vunknown.owl".freeze, "test/data/ontology_files/cell.skos.rdf".freeze, "test/data/ontology_files/custom_obsolete.owl".freeze, "test/data/ontology_files/custom_properties.owl".freeze, "test/data/ontology_files/efo_gwas.skos.owl".freeze, "test/data/ontology_files/evoc_v2.9.zip".freeze, "test/data/ontology_files/fake_for_mappings.owl".freeze, "test/data/ontology_files/gene_ontology_ext_v1.0.obo.zip".freeze, "test/data/ontology_files/hp.obo".freeze, "test/data/ontology_files/ont_dup_names.zip".freeze, "test/data/ontology_files/radlex_owl_v3.0.1.zip".freeze, "test/data/ontology_files/tao.obo".freeze, "test/data/ontology_files/umls_semantictypes.ttl".freeze, "test/data/ontology_files/zip_missing_master_file.zip".freeze, "test/docker_infrastructure.rb".freeze, "test/http_cache/test_http_cache.rb".freeze, "test/models/notes/test_note.rb".freeze, "test/models/test_category.rb".freeze, "test/models/test_class.rb".freeze, "test/models/test_group.rb".freeze, "test/models/test_instances.rb".freeze, "test/models/test_mappings.rb".freeze, "test/models/test_metric.rb".freeze, "test/models/test_ontology.rb".freeze, "test/models/test_ontology_common.rb".freeze, "test/models/test_ontology_format.rb".freeze, "test/models/test_ontology_submission.rb".freeze, "test/models/test_project.rb".freeze, "test/models/test_provisional_class.rb".freeze, "test/models/test_provisional_relation.rb".freeze, "test/models/test_review.rb".freeze, "test/models/test_slice.rb".freeze, "test/models/test_submission_status.rb".freeze, "test/models/user/test_subscription.rb".freeze, "test/models/user/test_user.rb".freeze, "test/models/user/test_user_authentication.rb".freeze, "test/parser/test_owl_api_command.rb".freeze, "test/rack/authorization.ru".freeze, "test/rack/serializer.ru".freeze, "test/rack/test_request_authorization.rb".freeze, "test/rack/test_request_formats.rb".freeze, "test/security/test_access_control.rb".freeze, "test/serializer/test_serializer_json.rb".freeze, "test/serializer/test_serializer_xml.rb".freeze, "test/serializer/test_to_flex_hash.rb".freeze, "test/test_case.rb".freeze, "test/test_log_file.rb".freeze, "test/util/test_notifications.rb".freeze, "test/util/test_ontology_csv_writer.rb".freeze]
  s.homepage = "https://github.com/ncbo/ontologies_linked_data".freeze
  s.rubygems_version = "2.5.2.2".freeze
  s.summary = "This library can be used for interacting with a 4store instance that stores NCBO-based ontology information. Models in the library are based on Goo. Serializers support RDF serialization as Rack Middleware and automatic generation of hypermedia links.".freeze
  s.test_files = ["test/console.rb".freeze, "test/data/destroy_test_data.rb".freeze, "test/data/generate_test_data.rb".freeze, "test/data/ontology_files/BRO_for_csv.owl".freeze, "test/data/ontology_files/BRO_v3.1.owl".freeze, "test/data/ontology_files/BRO_v3.2.1_v3.2.1.owl".freeze, "test/data/ontology_files/BRO_v3.2.owl".freeze, "test/data/ontology_files/BRO_v3.3.owl".freeze, "test/data/ontology_files/BRO_v3.4.owl".freeze, "test/data/ontology_files/BRO_v3.5.owl".freeze, "test/data/ontology_files/CNO_05.owl".freeze, "test/data/ontology_files/CellLine_OWL_BioPortal_v1.0.owl".freeze, "test/data/ontology_files/CogPO12142010.owl".freeze, "test/data/ontology_files/OntoMA.1.1_vVersion_1.1_Date__11-2011.OWL".freeze, "test/data/ontology_files/SBO.obo".freeze, "test/data/ontology_files/SDO.zip".freeze, "test/data/ontology_files/XCTontologyvtemp2_vvtemp2.zip".freeze, "test/data/ontology_files/aero.owl".freeze, "test/data/ontology_files/cdao_vunknown.owl".freeze, "test/data/ontology_files/cell.skos.rdf".freeze, "test/data/ontology_files/custom_obsolete.owl".freeze, "test/data/ontology_files/custom_properties.owl".freeze, "test/data/ontology_files/efo_gwas.skos.owl".freeze, "test/data/ontology_files/evoc_v2.9.zip".freeze, "test/data/ontology_files/fake_for_mappings.owl".freeze, "test/data/ontology_files/gene_ontology_ext_v1.0.obo.zip".freeze, "test/data/ontology_files/hp.obo".freeze, "test/data/ontology_files/ont_dup_names.zip".freeze, "test/data/ontology_files/radlex_owl_v3.0.1.zip".freeze, "test/data/ontology_files/tao.obo".freeze, "test/data/ontology_files/umls_semantictypes.ttl".freeze, "test/data/ontology_files/zip_missing_master_file.zip".freeze, "test/docker_infrastructure.rb".freeze, "test/http_cache/test_http_cache.rb".freeze, "test/models/notes/test_note.rb".freeze, "test/models/test_category.rb".freeze, "test/models/test_class.rb".freeze, "test/models/test_group.rb".freeze, "test/models/test_instances.rb".freeze, "test/models/test_mappings.rb".freeze, "test/models/test_metric.rb".freeze, "test/models/test_ontology.rb".freeze, "test/models/test_ontology_common.rb".freeze, "test/models/test_ontology_format.rb".freeze, "test/models/test_ontology_submission.rb".freeze, "test/models/test_project.rb".freeze, "test/models/test_provisional_class.rb".freeze, "test/models/test_provisional_relation.rb".freeze, "test/models/test_review.rb".freeze, "test/models/test_slice.rb".freeze, "test/models/test_submission_status.rb".freeze, "test/models/user/test_subscription.rb".freeze, "test/models/user/test_user.rb".freeze, "test/models/user/test_user_authentication.rb".freeze, "test/parser/test_owl_api_command.rb".freeze, "test/rack/authorization.ru".freeze, "test/rack/serializer.ru".freeze, "test/rack/test_request_authorization.rb".freeze, "test/rack/test_request_formats.rb".freeze, "test/security/test_access_control.rb".freeze, "test/serializer/test_serializer_json.rb".freeze, "test/serializer/test_serializer_xml.rb".freeze, "test/serializer/test_to_flex_hash.rb".freeze, "test/test_case.rb".freeze, "test/test_log_file.rb".freeze, "test/util/test_notifications.rb".freeze, "test/util/test_ontology_csv_writer.rb".freeze]

  s.installed_by_version = "2.5.2.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<goo>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<oj>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<bcrypt>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rack>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rubyzip>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<libxml-ruby>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<rsolr>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<pony>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<omni_logger>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<ncbo_resource_index>.freeze, [">= 0"])
      s.add_development_dependency(%q<email_spec>.freeze, [">= 0"])
    else
      s.add_dependency(%q<goo>.freeze, [">= 0"])
      s.add_dependency(%q<json>.freeze, [">= 0"])
      s.add_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_dependency(%q<oj>.freeze, [">= 0"])
      s.add_dependency(%q<bcrypt>.freeze, [">= 0"])
      s.add_dependency(%q<rack>.freeze, [">= 0"])
      s.add_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_dependency(%q<rubyzip>.freeze, [">= 0"])
      s.add_dependency(%q<libxml-ruby>.freeze, [">= 0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_dependency(%q<rsolr>.freeze, [">= 0"])
      s.add_dependency(%q<pony>.freeze, [">= 0"])
      s.add_dependency(%q<omni_logger>.freeze, [">= 0"])
      s.add_dependency(%q<ncbo_resource_index>.freeze, [">= 0"])
      s.add_dependency(%q<email_spec>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<goo>.freeze, [">= 0"])
    s.add_dependency(%q<json>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<oj>.freeze, [">= 0"])
    s.add_dependency(%q<bcrypt>.freeze, [">= 0"])
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<rubyzip>.freeze, [">= 0"])
    s.add_dependency(%q<libxml-ruby>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<rsolr>.freeze, [">= 0"])
    s.add_dependency(%q<pony>.freeze, [">= 0"])
    s.add_dependency(%q<omni_logger>.freeze, [">= 0"])
    s.add_dependency(%q<ncbo_resource_index>.freeze, [">= 0"])
    s.add_dependency(%q<email_spec>.freeze, [">= 0"])
  end
end
