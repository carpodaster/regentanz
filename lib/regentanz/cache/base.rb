module Regentanz

  module Cache

    class Base

      # Checks if +instance_or_class+ complies to cache backend duck type,
      # ie. if it reponds to all mandatory methods
      def self.lint(instance_or_class)
        [:add, :available?, :expire!, :valid?].inject(true) do |memo, method|
          memo && instance_or_class.respond_to?(method)
        end
      end

      # Stores cache +value+ as +key+.
      def add(key, value); end

      # Checks if cache under +key+ is available.
      def available?(key); end

      # Deletes cache under +key+.
      def expire!(key); end

      # Checks if cache under +key+ is still valid.
      def valid?(key); end

    end

  end
  
end