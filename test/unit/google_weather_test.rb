require File.join(File.dirname(__FILE__), '..', 'test_helper')

class GoogleWeatherTest < ActiveSupport::TestCase

  TEST_CACHE_FILE_NAME = File.join(Regentanz.configuration.cache_dir, "regentanz_test_cache.xml")

  def setup
    # FIXME Remove ActionMailer
    ActionMailer::Base.deliveries.clear
		# Ensure test mode
		Regentanz.configure { |config| config.do_not_get_weather = true }
  end

  def teardown
    File.unlink(TEST_CACHE_FILE_NAME) if File.exists?(TEST_CACHE_FILE_NAME)
    File.unlink(Regentanz.configuration.retry_marker) if File.exists?(Regentanz.configuration.retry_marker)
  end

	test "should initialize with options hash" do
		Regentanz::GoogleWeather.any_instance.expects(:get_weather).never()
		options = { :location => "Test Valley", :lang => "es" } 
		obj = Regentanz::GoogleWeather.new(options)
		assert_equal "Test Valley", obj.location
		assert_equal "es", obj.lang
	end

	test "should be compatible with old constructor" do
		Regentanz::GoogleWeather.any_instance.expects(:get_weather).never()
		obj = Factory(:google_weather, :location => "Test Valley")
		assert_equal "Test Valley", obj.location
		assert_equal "de", obj.lang
	end

  def test_should_create_marker_file_and_send_email_if_invalid_xml_file_has_been_found
    stub_valid_xml_api_response!
    Regentanz::GoogleWeather.any_instance.expects(:after_api_failure_detected) # callback
    
    weather = Factory(:google_weather)
    assert !File.exists?(Regentanz.configuration.retry_marker)
    create_invalid_xml_response(TEST_CACHE_FILE_NAME)

    assert_emails 1 do
      weather.get_weather!
      assert File.exists?(Regentanz.configuration.retry_marker)
    end
  end

  def test_should_send_email_after_marker_file_was_deleted
    File.new(Regentanz.configuration.retry_marker, "w+").close
    Regentanz.configuration.expects(:retry_ttl).returns(0); sleep 0.2
    stub_valid_xml_api_response!
    Regentanz::GoogleWeather.any_instance.expects(:after_api_failure_resumed) # callback

    weather = Factory(:google_weather)
    assert File.exists?(Regentanz.configuration.retry_marker)
    create_invalid_xml_response(TEST_CACHE_FILE_NAME)

    assert_emails 1 do
      weather.get_weather!
      assert !File.exists?(Regentanz.configuration.retry_marker)
    end
  end

  test "should have lang option" do 
    weather = Factory(:google_weather, :lang => :es)
    assert_equal "es", weather.lang
  end

  def test_should_calculate_sunrise_and_sunset_based_on_geodata
    weather = Regentanz::GoogleWeather.new("Berlin", weather_options(:geo_location => nil) )
    assert weather.respond_to? :sunrise
    assert weather.respond_to? :sunset
    assert_nil weather.sunrise
    assert_nil weather.sunset

    lat = 52.5163253260716
    lng = 13.3780860900879

    weather = Regentanz::GoogleWeather.new("Berlin", weather_options(:geodata => {:lat => lat, :lng => lng}) )
    assert weather.sunrise.is_a? Time
    assert weather.sunset.is_a? Time
  end

  test "should return cache filename" do
    obj  = Factory(:google_weather, :cache_id => "foo")
    assert_equal File.join(Regentanz.configuration.cache_dir, "#{Regentanz.configuration.cache_prefix}_foo.xml"), obj.cache_filename
  end

  protected

  def create_invalid_xml_response(filename)
    File.open(filename, "w+") do |f|
      f.write '<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>302 Moved</TITLE></HEAD><BODY>
<H1>302 Moved</H1>
The document has moved
<A HREF="http://sorry.google.com/sorry/?continue=http://www.google.com/ig/api%3Fweather%3D86747%252CGermany%26hl%3Dde">here</A>.
</BODY></HTML>
'
    end
  end

  # Stub Net::HTTP.get_response to return a semi-dynamic (ie. current date) xml
  # response-
  def stub_valid_xml_api_response!
    xml_templ = ERB.new <<-EOF
<?xml version="1.0"?>
<xml_api_reply version="1">
    <weather module_id="0" tab_id="0" mobile_row="0" mobile_zipped="1" row="0" section="0" >
        <forecast_information>
            <city data="Berlin, Berlin"/><postal_code data=Berlin,Germany"/>
            <latitude_e6 data=""/>
            <longitude_e6 data=""/>
            <forecast_date data="<%= Date.today.strftime("%Y-%m-%d") %>"/>
            <current_date_time data="<%= 5.minutes.ago.utc.strftime("%Y-%m-%d %H:%M:00") %> +0000"/>
            <unit_system data="SI"/>
        </forecast_information>
        <current_conditions>
            <condition data="Klar"/><temp_f data="77"/>
            <temp_c data="25"/>
            <humidity data="Feuchtigkeit: 57 %"/>
            <icon data="/ig/images/weather/sunny.gif"/>
            <wind_condition data="Wind: W mit 24 km/h"/>
        </current_conditions>
        <forecast_conditions>
            <day_of_week data="Do."/><low data="16"/>
            <high data="31"/>
            <icon data="/ig/images/weather/chance_of_rain.gif"/>
            <condition data="Vereinzelt Regen"/>
        </forecast_conditions>
    </weather>
</xml_api_reply>
EOF
    mock_response = mock()
    mock_response.stubs(:body).returns(xml_templ.result)
    Net::HTTP.stubs(:get_response).returns(mock_response)
  end

  # Return a few default options for the test environment
  def weather_options(options = {})
    {:cache_id => "test"}.merge(options.symbolize_keys!)
  end

end
