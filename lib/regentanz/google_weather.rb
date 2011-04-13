module Regentanz
  class GoogleWeather
    require 'iconv'
    require 'net/http'
    require 'rexml/document'
    require 'ostruct'

    include Math # OPTIMIZE move to "Solar"-module, see below

    XML_ENCODING = 'LATIN1' # source encoding of the XML data

    BASE_URL     = "http://www.google.com/ig/api"
    CACHE_PATH   = "#{RAILS_ROOT}/public/cache/google_weather_"
    CACHE_TTL    = 14400 # 4 hours
    RETRY_TTL    = 3600  # 1 hour
    RETRY_MARKER = CACHE_PATH + "api_retry.txt"

    attr_reader :lang, :location, :xml

    # Creates an object and queries the weather API.
    #
    # === Parameters
    # * +location+ String to pass to Google's weather API
    # * +options+ A hash
    #
    # === Available options
    # * +:cache_id+ enables caching with a unique identifier to locate a cached file
    # * +:do_not_get_weather+ prohibits getting weather data right away (ie. trying cache or calling the API). Intended for use with GoogleWeather#get_weather!
    # * +:geodata+ a hash with keys :lat and :lng, required for sunset/-rise calculations
    # * +lang+ Desired language for the returned results (Defaults to :de)
    # * +:suppress_stderr_output+ prohibits output to $stderr if set
    def initialize(location, options = {})
      @options  = options.symbolize_keys
      @location = location
      @lang     = options[:lang] ? options[:lang].to_s : "de"
      @geodata  = options[:geodata] if options[:geodata] and options[:geodata][:lat] and options[:geodata][:lng]
      get_weather() unless @options[:do_not_get_weather]
    end

    # Returns an OpenStruct object with attributes corresponding to the
    # XML elements of <current_conditions>...</current_conditions>
    def current
      @current ||= OpenStruct.new(@current_raw)
    end

    # Returns the full path to the cache file based upon CACHE_PATH and _cache_id_
    def cache_filename
      @cache_filename ||= "#{CACHE_PATH}#{@options[:cache_id]}.xml"
    end

    # Returns an array of OpenStruct objects with attributes corresponding to the
    # XML elements of <forecast_conditions>...</forecast_conditions>
    def forecast
      @forecast ||= @forecast_raw.map { |fc| OpenStruct.new(fc) }
    end

    # Loads weather data from known data sources (ie. cache or external API)
    def get_weather!; get_weather(); end

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

    private

    # Encapsulate output of error messages. Will output to $stderr unless
    # @options[:suppress_stderr_output] is set
    #
    # === Parameters
    # * +output+: String to output
    def error_output(output)
      $stderr.puts output unless @options[:suppress_stderr_output]
    end

    # Proxies +do_request+ and +parse_request+
    def get_weather
      if cache_valid?
        @xml = convert_encoding(load_from_cache)
      else
        expire_cache!
        @xml = convert_encoding(do_request(BASE_URL + "?weather=#{CGI::escape(@location)}&hl=#{@lang}"))
        cache_request() if @xml
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
      @current_raw = {}; @forecast_raw = []
      begin
        @doc = REXML::Document.new(@xml)
        @doc.elements['xml_api_reply/weather/current_conditions'].each_element do |ele|
          @current_raw.merge! parse_node(ele)
        end if @doc.elements['xml_api_reply/weather/current_conditions']

        @doc.elements.each('xml_api_reply/weather/forecast_conditions') do |forecast_ele|
          fc = {}; forecast_ele.each_element { |ele| fc.merge! parse_node(ele) }
          @forecast_raw << fc
        end if @doc.elements['xml_api_reply/weather/forecast_conditions']
      rescue REXML::ParseException => e
        error_output(e.message)
      end
    end

    # Handles some special treatment for certain sub-elements, transforms _element_
    # into a hash and returns it.
    #
    # === Parameters
    # * +element+ childnode of type REXML::Element
    def parse_node(element)
      hash = {}
      hash.merge! parse_style(element.attribute("data").to_s) if element.name == "icon"
      if element.name == "humidity"
        # Handle the small whitespace just before the '%'
        hash.merge! element.name => element.attribute("data").to_s.gsub(/(\d+).+%$/, '\1 %')
      elsif element.name == "icon"
        # We want the full URL
        hash.merge! element.name => "http://www.google.com" + element.attribute("data").to_s
      elsif (element.name == "high" or element.name == "low") and @lang == "en"
        # Forecast-temperatures in EN are listed in °F; we fix that here
        temp_f = element.attribute("data").to_s.to_i
        hash.merge! element.name => ( temp_f - 32 ) * 5 / 9
      else
        hash.merge! element.name => element.attribute("data").to_s
      end
      hash
    end

    # Extracts a name for the weather condition from the icon name. Intended to
    # be used as CSS style class name.
    #
    # === Parameters
    # * +path+ an URI-string to Google's weather icon
    def parse_style(path)
      hash = {}
      unless path.blank?
        style = File.basename(path)
        style = style.slice(0, style.rindex(".")).gsub(/_/, '-')
        hash = { "style" => style }
      end
      hash
    end

    # Evaluates to +true+ if a _cache_id_ option is set.
    def cache_available?
      @options[:cache_id].present?
    end

    # Returns +true+ if a given cache file contains data not older than CACHE_TTL seconds
    def cache_valid?
      validity = false
      if cache_available? and File.exists?(cache_filename)
        begin
          doc  = REXML::Document.new(load_from_cache)
          node = doc.elements["xml_api_reply/weather/forecast_information/current_date_time"]
          time = node.attribute("data").to_s.to_time if node
          validity = time ? time > CACHE_TTL.seconds.ago : false
        rescue REXML::ParseException
          retry_after_incorrect_api_reply
          validity = recovering_from_incorrect_api_reply? # not really valid, but we need to wait a bit.
        end
      end
      validity
    end

    # Reads cache file and returns its contents, blindly assuming its XML
    def load_from_cache
      File.open(cache_filename, "r") { |file| file.read }
    end

    # Unlinks the cache file
    def expire_cache!
      File.delete(cache_filename) if File.exists?(cache_filename)
    end

    # Writes the instance var +xml+ to the cache file if the cache path is available
    def cache_request
      if cache_available? and @xml
        begin
          File.open(cache_filename, "w") { |file| file.puts @xml }
        rescue => e
          error_output(e.message)
        end
      end
    end

    # Converts a string from XML_ENCODING to UTF-8 using the Iconv library.
    #
    # === Note
    # There seems to be a difference handling of encodings between Kauperts RF (Rails 2.3.x)
    # and Kauperts 2.2.2). The XML source document is delivered LATIN1-encoded. It might
    # change in the future, in which case the constant XML_ENCODING should be modified.
    #
    # === Parameters
    # * +str+ data to convert
    def convert_encoding str
      # TODO have an eye on encoding errors
      self.class::XML_ENCODING != "UTF-8" ? Iconv.iconv("UTF-8", self.class::XML_ENCODING, str).flatten.join(" ") : str
    end

    # Returns +true+ if a RETRY_MARKER file exists
    def recovering_from_incorrect_api_reply?
      File.exists?(RETRY_MARKER)
    end

    # Brings the outbound API-calls to a halt for RETRY_TTL seconds by creating
    # a marker file. Flushes the incorrect cached API response after RETRY_TTL
    # seconds.
    def retry_after_incorrect_api_reply
      if !recovering_from_incorrect_api_reply?
        # We are run for the first time, create the marker file
        # TODO remove dependency to SupportMailer class
        SupportMailer.deliver_weather_retry_marker_notification!(self, :set)
        File.new(RETRY_MARKER, "w+").close
      elsif recovering_from_incorrect_api_reply? and File.new(RETRY_MARKER).mtime < RETRY_TTL.seconds.ago
        # Marker file is old enough, delete the (invalid) cache file and remove the marker_file
        expire_cache!
        File.delete(RETRY_MARKER) if File.exists?(RETRY_MARKER)
        SupportMailer.deliver_weather_retry_marker_notification!(self, :unset)
      end
    end

    # The following code was taken from
    # http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/264573
    #
    # OPTIMIZE split into a seperate module

    def deg_to_rad(degrees)
      degrees*PI/180
    end

    def rad_to_deg(radians)
      radians*180/PI
    end

    def sun_rise_set(mode, lat, lng, zenith = 90.8333)
      #step 1: first calculate the day of the year
      mode = mode.to_sym
      date = Date.today
      n=date.yday

      #step 2: convert the longitude to hour value and calculate an approximate time
      lng_hour=lng/15
      t = n+ ((6-lng_hour)/24) if mode==:sunrise
      t = n+ ((18-lng_hour)/24) if mode==:sunset

      #step 3: calculate the sun's mean anomaly
      m = (0.9856 * t) - 3.289

      #step 4: calculate the sun's true longitude
      l = (m+(1.1916 * sin(deg_to_rad(m))) + (0.020 * sin(deg_to_rad(2*m))) + 282.634) % 360

      #step 5a: calculate the sun's right ascension
      ra = rad_to_deg(atan(0.91764 * tan(deg_to_rad(l)))) % 360

      #step 5b: right ascension value needs to be in the same quadrant as L
      lquadrant  = (l/90).floor*90
      raquadrant = (ra/90).floor*90
      ra         = ra+(lquadrant-raquadrant)

      #step 5c: right ascension value needs to be converted into hours
      ra/=15

      #step 6: calculate the sun's declination
      sin_dec = 0.39782 * sin(deg_to_rad(l))
      cos_dec = cos(asin(sin_dec))
      #step 7a: calculate the sun's local hour angle
      cos_h = (cos(deg_to_rad(zenith)) - (sin_dec * sin(deg_to_rad(lat)))) / (cos_dec * cos(deg_to_rad(lat)))

      return nil if (not (-1..1).include? cos_h)

      #step 7b: finish calculating H and convert into hours
      h = (360 - rad_to_deg(acos(cos_h)))/15 if mode==:sunrise
      h = (rad_to_deg(acos(cos_h)))/15       if mode==:sunset

      #step 8: calculate local mean time
      t = h + ra - (0.06571 * t) - 6.622
      t %=24

      #step 9: convert to UTC
      return (date.to_datetime+(t - lng_hour)/24).to_time.getlocal
    end

  end
end