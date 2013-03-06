require_relative 'link'
require_relative 'resource'

module LinkedData
  module Hypermedia
    def self.generate_links(object)
      return {} if !object.is_a?(LinkedData::Hypermedia::Resource) || object.class.hypermedia_settings[:link_to].empty?
      links = object.class.hypermedia_settings[:link_to]
      links_output = {}
      links.each do |link|
        links_output[link.type] = expand_link(link.path, object)
      end
      links_output
    end

    def self.expand_link(link, object)
      new_link = link.gsub(/(:[\w|\.]+)/).each do |match|
        if match.include?(".")
          parts = match.split(".")
          attribute = parts[0]
          attribute_method = parts[1]
          match = object.send(attribute.gsub(":", "")).send(attribute_method)
        elsif match.include?(":")
          match = object.send(match.to_s.gsub(":", ""))
        end
        match
      end
      new_link
    end
  end
end