module Regentanz

  module Cache

    # Implements file-based caching. Cache files are stored in
    # +Regentanz.configuration.cache_dir+ and are prefixed with
    # +Regentanz.configuration.cache_prefix+.
    class File < Regentanz::Cache::Base

      # Cache is available (n.b. not necessarily #valid?) if a file
      # exists for +key+
      def available?(key)
        ::File.exists?(filename(key)) rescue nil
      end

      # Unlinks the cache file for +key+
      def expire!(key)
        return false unless available?(key)
        begin
          ::File.delete(filename(key))
          true
        rescue
        end
      end

      def filename(key)
        ::File.join(Regentanz.configuration.cache_dir, "#{Regentanz.configuration.cache_prefix}_#{key}.xml")
      end

      # Retrieves content of #filename for +key+
      def get(key)
        if available?(key)
          ::File.open(filename(key), "r") { |file| file.read } rescue nil
        end
      end

      # Stores +value+ in #filename for +key+
      def set(key, value)
        begin
          ::File.open(filename(key), "w") { |file| file.puts value }
          filename(key)
        rescue
        end
      end

      def valid?(key)
        return false unless available?(key)
        begin
          # TODO delegate XML parsing and verification
          doc  = REXML::Document.new(get(key))
          node = doc.elements["xml_api_reply/weather/forecast_information/current_date_time"]
          time = node.attribute("data").to_s.to_time if node
          time > Regentanz.configuration.cache_ttl.seconds.ago
        rescue
          # TODO pass exception upstream until properly delegated in the first place?
        end
      end

      # Returns whether or not weather retrieval from the API
      # is currently waiting for a timeout to expire; here: existence of
      # a retry marker file
      def waiting_for_retry?
        ::File.exists?(Regentanz.configuration.retry_marker)
      end

      # Checks if we've waited long enough. Deletes a possible retry
      # marker file (and returns true) if so or returns false if not
      def retry!
        marker = Regentanz.configuration.retry_marker
        if waiting_for_retry? and ::File.new(marker).mtime < Regentanz.configuration.retry_ttl.seconds.ago
          ::File.delete(marker) if ::File.exists?(marker)
          true
        end
      end

      # Persists the timeout state by writing a retry_marker file
      def set_retry_state!
        ::File.open(Regentanz.configuration.retry_marker, "w+").close
        waiting_for_retry?
      end
      
    end

  end

end