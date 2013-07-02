require 'xml'

module LinkedData
  module Serializers
    class XML
      def self.serialize(obj, options)
        links = {}
        hash = obj.to_flex_hash(options) do |hash, hashed_obj|
          if hashed_obj.is_a?(Goo::Base::Resource)
            hash["id"] = hashed_obj.id.to_s.gsub("http://data.bioontology.org/metadata/", LinkedData.settings.rest_url_prefix)
            links_xml = generate_links(hashed_obj)
            links[hash["id"]] = links_xml unless links_xml.empty?
          end
        end
        cls = obj.kind_of?(Array) || obj.kind_of?(Set) ? obj.first.class : obj.class
        cls = options[:class_name] if options[:class_name]
        to_xml(hash, convert_class_name(cls), links).to_s
      end

      def self.to_xml(object, type, links = nil)
        doc = ::XML::Document.new
        if object.nil? || object.respond_to?("empty?") && object.empty?
          doc.root = ::XML::Node.new("empty")
          return doc
        end

        if object.kind_of?(Hash)
          root = convert_hash(object, type, links)
        elsif object.kind_of?(Array)
          root = convert_array(object, type, links)
        else
          root = ::XML::Node.new(object.to_s)
        end

        doc.root = root
        doc
      end

      private

      def self.generate_links(object)
        return {} if !object.is_a?(LinkedData::Hypermedia::Resource) || object.class.hypermedia_settings[:link_to].empty?
        links = object.class.hypermedia_settings[:link_to]
        links_output = ::XML::Node.new("links")
        self_link = ::XML::Node.new("self")
        self_link['href'] = object.id.to_s.gsub("http://data.bioontology.org/metadata/", LinkedData.settings.rest_url_prefix)
        self_link['rel'] = object.class.type_uri.to_s
        links_output << self_link
        links.each do |link|
          link_xml = ::XML::Node.new(link.type)
          link_xml['href'] = LinkedData::Hypermedia.expand_link(link, object)
          link_xml['rel'] = link.type_uri.to_s if link.type_uri
          links_output << link_xml
        end
        return links_output
      end

      def self.convert_hash(hash, type, links = {})
        hash_container = ::XML::Node.new(type)
        element = nil
        hash.each do |key, value|
          if value.kind_of?(Hash)
            element = convert_hash(value, key, links)
          elsif value.kind_of?(Enumerable)
            element = convert_array(value, key, links)
          else
            element = ::XML::Node.new(key)
            element << value.to_s
          end
          hash_container << element
          if hash["id"] && links[hash["id"]]
            hash_container << links[hash["id"]]
          end
        end
        hash_container
      end

      def self.convert_array(array, type, links = {})
        root = ::XML::Node.new(type.to_s + "Collection")
        array.each do |item|
          element = ::XML::Node.new(type.to_s)
          if item.kind_of?(Hash)
            element = convert_hash(item, type, links)
          else
            element << item
          end
          root << element
        end
        root
      end

      def self.convert_class_name(cls)
        name = cls.name.split('::').last
        name[0] = name[0].downcase
        name
      end
    end
  end
end