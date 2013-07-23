require 'active_support/core_ext/string'
require 'cgi'

module LinkedData
  module Models
    class Base < Goo::Base::Resource
      include LinkedData::Hypermedia::Resource
      include LinkedData::HTTPCache::CachableResource

      def save(*args)
        super(*args)
        self.cache_write
      end

      def delete(*args)
        super(*args)
        self.cache_invalidate
      end
    end
  end
end
