module LinkedData
  module Serializers
    class XML
      def self.serialize(obj, options)
        hash = obj.to_flex_hash(options)
        cls = obj.kind_of?(Array) || obj.kind_of?(Set) ? obj.first.class : obj.class
        cls = options[:class_name] if options[:class_name]
        to_xml(hash, convert_class_name(cls)).to_s
      end

      def self.to_xml(object, type)
        doc = ::XML::Document.new

        if object.kind_of?(Hash)
          root = convert_hash(object, type)
        elsif object.kind_of?(Array)
          root = convert_array(object, type)
        else
          root = ::XML::Node.new(object.to_s)
        end

        doc.root = root
        doc
      end

      private

      def self.convert_hash(hash, type)
        hash_container = ::XML::Node.new(type)
        element = nil
        hash.each do |key, value|
          value = convert_hash(hash) if value.kind_of?(Hash)
          if value.kind_of?(Enumerable)
            element = convert_array(value, key)
          else
            element = ::XML::Node.new(key)
            element << value.to_s rescue binding.pry
          end
          hash_container << element
        end
        hash_container
      end

      def self.convert_array(array, type)
        root = ::XML::Node.new(type.to_s + "Collection")
        array.each do |item|
          element = ::XML::Node.new(type.to_s)
          if item.kind_of?(Hash)
            element = convert_hash(item, type)
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