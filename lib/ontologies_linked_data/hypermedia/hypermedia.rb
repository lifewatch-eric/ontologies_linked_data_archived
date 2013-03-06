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
        links_output[link.type] = $REST_URL_PREFIX + expand_link(link.path, object)
      end
      links_output
    end

    def self.expand_link(link, object)
      new_link = link.gsub(/(:[\w|\.]+)/).each do |match|
        if match.include?(".")
          method_queue = match.split(".")
          match = get_nested_value(object, method_queue)
        elsif match.include?(":")
          match = object.send(match.to_s.gsub(":", ""))
        end
        CGI.escape(match)
      end
      new_link
    end

    def self.get_nested_value(object, queue)
      attribute = queue.shift
      value = object.send(attribute.gsub(":", ""))
      return value if queue.empty?
      get_nested_value(value, queue)
    end

  end
end