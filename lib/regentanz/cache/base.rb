module Regentanz

  module Cache

    class Base

      # Checks if +instance_or_class+ complies to cache backend duck type,
      # ie. if it reponds to all mandatory methods
      def self.lint(instance_or_class)
        instance = instance_or_class.is_a?(Class) ? instance_or_class.new : instance_or_class
        [:set, :get, :available?, :expire!, :valid?].inject(true) do |memo, method|
          memo && instance.respond_to?(method)
        end
      end

      # Returns a unique alpha-numeric cache key
      def self.sanitize_key(key)
        Digest::SHA1.hexdigest("--#{key}--#{Time.now}")
      end

      # Stores cache +value+ as +key+.
      def set(key, value); end

      # Retrieves cached value from +key+.
      def get(key); end

      # Checks if cache under +key+ is available.
      def available?(key); end

      # Deletes cache under +key+.
      def expire!(key); end

      # Checks if cache under +key+ is still valid.
      def valid?(key); end

    end

  end
  
end