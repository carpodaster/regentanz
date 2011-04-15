module Regentanz

  class Configuration

    DEFAULT_OPTIONS = [
      :base_url,
      :cache_path,
      :cache_ttl,
      :retry_marker,
      :retry_ttl
    ]

    OPTIONS = DEFAULT_OPTIONS + [
      :do_not_get_weather,
      :suppress_stderr_output
    ]

    # Define default values
    @@default_base_url     = "http://www.google.com/ig/api"
    @@default_cache_path   = "#{RAILS_ROOT}/public/cache/google_weather_"
    @@default_cache_ttl    = 14400 # 4 hours
    @@default_retry_ttl    = 3600  # 1 hour
    @@default_retry_marker = @@default_cache_path + "api_retry.txt"
    
    OPTIONS.each { |opt|  attr_accessor(opt) }
    DEFAULT_OPTIONS.each { |cvar| cattr_reader(:"default_#{cvar}", :instance_reader => false) } # class getter for all DEFAULT_OPTION cvars

    # Stores global configuration information for +Regentanz+.
    #
    # == Default Options
    # * +base_url+: HTTP API, request-specific calls will be appended (default: +http://www.google.com/ig/api+)
    # * +cache_path+: defaults to "#{RAILS_ROOT}/public/cache/google_weather_"
    # * +cache_ttl+: time in seconds for which cache data is considered valid. Default: 14400 (4 hours).
    # * +retry_ttl+: time in seconds Regentanz should wait until it tries to call the API again when it failed before. Default: 3600 (1 hour).
    # * +retry_marker+: persist a marker-file here to indicate a failed API state. Default: +cache_path+api_retry.txt
    #
    # == Options
    # * +do_not_get_weather+: don't try to retrieve weather data, neither from cache nor remote API. Intended for testing.
    # * +suppress_stderr_output+: called from GoogleWeather#error_output, silences Regentanz' output. Intended for testing.
    def initialize(*args)
      DEFAULT_OPTIONS.each do |option|
        self.send(:"#{option}=", self.class.send(:class_variable_get, :"@@default_#{option}") )
      end
    end
    
  end

end