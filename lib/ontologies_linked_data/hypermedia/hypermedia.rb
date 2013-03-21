require 'cgi'
require_relative 'link'
require_relative 'resource'

module LinkedData
  module Hypermedia
    def self.generate_links(object)
      return {} if !object.is_a?(LinkedData::Hypermedia::Resource) || object.class.hypermedia_settings[:link_to].empty?
      links = object.class.hypermedia_settings[:link_to]
      links_output = {}
      links.each do |link|
        links_output[link.type] = LinkedData.settings.rest_url_prefix + expand_link(link, object)
      end
      links_output
    end

    ##
    # Take a provided link and expand tokens to their values
    # Handles calling methods on nested objects
    # link syntax:
    #   path/to/:ontology
    #     :ontology is an attribute on object
    #   path/to/:ontology.acronym
    #     :ontology.acronym will call `ontology` on object then `acronym` on the returned object from `ontology`
    #   path/to/:submission.ontology.acronym
    #     :submission.ontology.acronym will recurse even deeper
    #
    # PROTIP: Avoid recursing in loops with objects that contain each other as attributes
    def self.expand_link(link, object)
      if link.is_a?(String)
        path = link
      else
        path = link.path.is_a?(Proc) ? link.path.call(object) : link.path
      end

      new_path = path.gsub(/(:[\w|\.]+)/).each do |match|
        if match.include?(".")
          method_queue = match.split(".")
          match = get_nested_value(object, method_queue)
        elsif match.include?(":")
          match = object.send(match.to_s.gsub(":", ""))
        end
        CGI.escape(match)
      end
      new_path
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