module Regentanz
  class GoogleWeather
    require 'net/http'
    require 'rexml/document'
    require 'ostruct'

    include Astronomy
    include Callbacks

    attr_accessor :location, :cache_id
    attr_reader   :cache, :current, :forecast, :lang, :parser, :xml

    # Creates an object and queries the weather API.
    #
    # === Parameters
    # * +options+ A hash
    #
    # === Available options
    # * +location+ String to pass to Google's weather API (mandatory)
    # * +cache_id+ enables caching with a unique identifier to locate a cached file
    # * +geodata+ a hash with keys :lat and :lng, required for sunset/-rise calculations
    # * +lang+ Desired language for the returned results (Defaults to "de")
    def initialize(*args)
      options = args.extract_options!
      @options  = options.symbolize_keys
      @parser = Parser::GoogleWeather.new
      self.location = args.first || options[:location]
      self.lang = options[:lang]

      # Activate caching
      if Regentanz.configuration.cache_backend
        @cache    = Regentanz.configuration.cache_backend.new if Regentanz.configuration.cache_backend
        @cache_id = options[:cache_id] || Regentanz.configuration.cache_backend.sanitize_key(@location)
      end
      
      @geodata  = options[:geodata] if options[:geodata] and options[:geodata][:lat] and options[:geodata][:lng]
      get_weather() unless Regentanz.configuration.do_not_get_weather
    end

    # Loads weather data from known data sources (ie. cache or external API)
    def get_weather!; get_weather(); end

    # Input sanitizer-setter, defaults to "de"
    def lang=(lang)
      @lang = lang.present? ? lang.to_s : "de"
    end

    # Provide an accessor to see if we actually got weather info at all.
    def present?
      @current_raw.present? or @forecast_raw.present?
    end

    def sunrise
      @sunrise ||= @geodata.blank? ? nil : sun_rise_set(:sunrise, @geodata[:lat], @geodata[:lng])
    end

    def sunset
      @sunset  ||= @geodata.blank? ? nil : sun_rise_set(:sunset, @geodata[:lat], @geodata[:lng])
    end

    def waiting_for_retry?
      @cache && @cache.waiting_for_retry?
    end

    private

    # Encapsulate output of error messages. Will output to $stderr unless
    # Regentanz.configuration.suppress_stderr_output is set
    #
    # === Parameters
    # * +output+: String to output
    def error_output(output)
      $stderr.puts output unless Regentanz.configuration.suppress_stderr_output
    end

    # Proxies +do_request+ and +parse_request+
    def get_weather
      if cache_valid?
        @xml = @parser.convert_encoding(@cache.get(@cache_id))
      else
        @xml = @parser.convert_encoding(do_request(Regentanz.configuration.base_url + "?weather=#{CGI::escape(@location)}&hl=#{@lang}"))
        if @cache
          @cache.expire!(@cache_id)
          @cache.set(@cache_id, @xml)
        end
    end
      parse_xml() if @xml
    end

    # Makes an outbound HTTP-request and returns the request body (ie. the XML)
    #
    # === Parameters
    # * +url+ API-URL with protocol, fqdn and URI
    def do_request(url)
      begin
        Net::HTTP.get_response(URI.parse(url)).body
      rescue => e
        error_output(e.message)
      end
    end

    # Extracts raw info for current weather conditions and forecasts which are
    # stored as hashes in instances variables: +current_raw+ and +forecast_raw+,
    # respectively.
    #
    # Assumes the instance var +xml+ is set.
    def parse_xml
      begin
        @current = @parser.parse_current!(@xml)
        @forecast = @parser.parse_forecast!(@xml)
      rescue REXML::ParseException => e
        error_output(e.message)
      end
    end

    # Returns +true+ if a given cache file contains data not older than Regentanz::Configuration#cache_ttl seconds
    # TODO properly use cache backend's #valid?
    def cache_valid?
      validity = false
      if @cache and @cache.available?(@cache_id)
        begin
          doc  = REXML::Document.new(@cache.get(@cache_id))
          node = doc.elements["xml_api_reply/weather/forecast_information/current_date_time"]
          time = node.attribute("data").to_s.to_time if node
          validity = time ? time > Regentanz.configuration.cache_ttl.seconds.ago : false
        rescue REXML::ParseException
          retry_after_incorrect_api_reply
          validity = waiting_for_retry? # not really valid, but we need to wait a bit.
        end
      end
      validity
    end

    # Brings the outbound API-calls to a halt for Regentanz::Configuration#retry_ttl seconds by creating
    # a marker file. Flushes the incorrect cached API response after Regentanz::Configuration#retry_ttl
    # seconds.
    def retry_after_incorrect_api_reply
      if !waiting_for_retry? and @cache
        # We are run for the first time, create the marker file
        # TODO remove dependency to SupportMailer class
        api_failure_detected # callback
        SupportMailer.deliver_weather_retry_marker_notification!(self, :set)
        @cache.set_retry_state!
      elsif @cache and @cache.unset_retry_state!
        # Marker file is old enough, delete the (invalid) cache file and remove the marker_file
        @cache.expire!(@cache_id)
        api_failure_resumed # callback
        SupportMailer.deliver_weather_retry_marker_notification!(self, :unset)
      end
    end

  end
end
