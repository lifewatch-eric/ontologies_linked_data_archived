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