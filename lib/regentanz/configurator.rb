module Regentanz
  class << self

    attr_writer :configuration
    def configuration #:nodoc:
      @configuration ||= Configuration.new
    end

    # Call this method to modify defaults in your initializers.
    # See Regentanz::Configuration for supported config options.
    #
    # === Example usage
    #   Regentanz.configure do |config|
    #     config.<supported_config_option> = :bar
    #   end
    def configure
      self.configuration ||= Configuration.new
        yield(configuration)
    end

  end
end