module Regentanz
  module TestHelper

    # Default values used for testing. Use this in your setup methods.
    # Configuration values can be overriden by supplying a block. See
    # Regentanz::Configuration for supported values.
    def setup_regentanz_test_configuration!
      Regentanz.configure do |config|
        config.retry_ttl              = Regentanz::Configuration.default_cache_ttl
        config.do_not_get_weather     = true
        config.retry_ttl              = Regentanz::Configuration.default_retry_ttl
        config.suppress_stderr_output = true
        yield config if block_given? # add settings or override above from client
      end
    end
  end
  
end

include Regentanz::TestHelper