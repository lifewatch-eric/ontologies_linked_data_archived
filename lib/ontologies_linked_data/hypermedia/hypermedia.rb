require 'cgi'
require_relative 'link'
require_relative 'resource'

module LinkedData
  module Hypermedia
    def self.generate_links(object)
      current_cls = object.respond_to?(:klass) ? object.klass : object.class
      return {} if !current_cls.ancestors.include?(LinkedData::Hypermedia::Resource) || current_cls.hypermedia_settings[:link_to].empty?
      links = current_cls.hypermedia_settings[:link_to]
      links_output = {}
      links.each do |link|
        expanded_link = expand_link(link, object)
        unless expanded_link.start_with?("http")
          expanded_link = LinkedData.settings.rest_url_prefix + expanded_link
        end
        links_output[link.type] = expanded_link
      end
      links_output
    end

    ##
    # Take a provided link as proc or string and return the result
    def self.expand_link(link, object)
      link.path.is_a?(Proc) ? link.path.call(object) : link.path
    end

    ##
    # Recurse until you hit the last nested value and return that
    def self.get_nested_value(object, queue)
      attribute = queue.shift
      value = object.send(attribute.gsub(":", ""))
      return value if queue.empty?
      get_nested_value(value, queue)
    end

  end
end