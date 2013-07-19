require 'digest/md5'
require 'time'

module LinkedData::HTTPCache
  REDIS = Redis.new(host: LinkedData.settings.redis_host, port: LinkedData.settings.redis_port)
  def self.invalidate_all
    key_set = LinkedData::HTTPCache::CachableResource::KEY_SET
    keys = REDIS.smembers(key_set)
    if keys
      keys.each_slice(500_000) {|chunk| REDIS.del chunk}
      REDIS.del key_set
    end
  end

  module CachableResource
    KEY_SET = "httpcache:keys"
    KEY_PREFIX = "httpcache:last_modified"
    COLLECTION_KEY_PREFIX = "httpcache:last_modified:collection"

    ##
    # Compare a last modified string to the last modified time for this object
    def last_modified_valid?(last_modified)
      cache_read.eql?(last_modified)
    end

    ##
    # Invalidate the cache entry for this object
    def cache_invalidate
      REDIS.hdel cache_prefix_and_segment, cache_key
      self.class.cache_collection_invalidate
    end

    ##
    # Invalidate all entries in the segment to which this object belongs
    def cache_segment_invalidate
      REDIS.del cache_prefix_and_segment
    end

    ##
    # Update the last modified date in the cache for this object
    def cache_write
      REDIS.hmset cache_prefix_and_segment, cache_key, Time.now.httpdate
      REDIS.sadd self.class.key_set, cache_prefix_and_segment
      self.class.cache_collection_write
    end

    ##
    # The last modified time for this object
    def cache_read
      (REDIS.hmget(cache_prefix_and_segment, cache_key) || []).first
    end
    alias :last_modified :cache_read

    ##
    # The cache key for this object
    def cache_key
      if self.class.cache_settings[:cache_key]
        self.class.cache_settings[:cache_key].call(self)
      else
        Digest::MD5.hexdigest(self.id)
      end
    end

    ##
    # The cache key and the segment for the current object
    def cache_prefix_and_segment
      self.class.key_prefix + current_segment
    end

    ##
    # The object's current segment
    def current_segment
      segment = self.class.cache_settings[:cache_segment]
      return "" if segment.nil?
      ":#{segment.call(self).join(':')}"
    end

    module ClassMethods
      ##
      # Wrappers for constants so they are available in instance
      def key_set() KEY_SET end
      def key_prefix() KEY_PREFIX end

      ##
      # Update the collection last modified date
      def cache_collection_write
        REDIS.hmset cache_collection_prefix, cache_collection_key, Time.now.httpdate
        REDIS.sadd KEY_SET, cache_collection_prefix
      end

      ##
      # Get the collection last modified date
      def cache_collection_read
        (REDIS.hmget(cache_collection_prefix, cache_collection_key) || []).first
      end

      ##
      # Get the collection last modified date
      def collection_last_modified
        cache_collection_read
      end

      ##
      # Compare a last modified string to the last modified time for this collection
      def collection_last_modified_valid?(last_modified)
        cache_collection_read.eql?(last_modified)
      end

      ##
      # Invalidate the cache entry for this collection
      def cache_collection_invalidate
        REDIS.hdel cache_collection_prefix, cache_collection_key
      end

      ##
      # The cache key for this collection
      def cache_collection_key
        name
      end

      ##
      # The prefix for this collection
      def cache_collection_prefix
        COLLECTION_KEY_PREFIX
      end
    end

    # Internal

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.store_settings(cls, type, setting)
      cls.hypermedia_settings ||= {}
      cls.hypermedia_settings[type] = setting
    end

    module ClassMethods
      # KEY_SET = LinkedData::HTTPCache::CachableResource::KEY_SET
      # KEY_PREFIX = LinkedData::HTTPCache::CachableResource::KEY_PREFIX
      # COLLECTION_KEY_PREFIX = LinkedData::HTTPCache::CachableResource::COLLECTION_KEY_PREFIX

      attr_accessor :cache_settings
      def cache_settings
        @cache_settings || {}
      end

      # Methods with these names will be created
      # for each entry, allowing values to be
      # stored on a per-class basis
      SETTINGS = [
        :cache_key,
        :cache_timeout,
        :cache_segment
      ]

      ##
      # Write methods on the class based on settings names
      SETTINGS.each do |method_name|
        define_method method_name do |*args|
          CachableResource.store_settings(self, method_name, args)
        end
      end
    end
  end
end


