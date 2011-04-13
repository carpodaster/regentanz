require File.dirname(__FILE__) + '/../test_helper'


class GoogleWeatherTest < ActionMailer::TestCase

  TEST_CACHE_FILE_NAME = RAILS_ROOT+"/google_weather_test_cache.xml"
  TEST_RETRY_MARKER = RAILS_ROOT+"/google_weather_test_api_retry.txt"


  def setup
    ActionMailer::Base.deliveries.clear
    GoogleWeather.redefine_const(:RETRY_MARKER, TEST_RETRY_MARKER)
    GoogleWeather.any_instance.stubs(:cache_filename => TEST_CACHE_FILE_NAME)
  end

  def teardown
    File.unlink(TEST_CACHE_FILE_NAME) if File.exists?(TEST_CACHE_FILE_NAME)
    File.unlink(TEST_RETRY_MARKER) if File.exists?(TEST_RETRY_MARKER)
  end

  test "should create marker file and send email if invalid xml file has been found" do
    stub_valid_xml_api_response!

    weather = GoogleWeather.new("Berlin", weather_options)
    assert !File.exists?(GoogleWeather::RETRY_MARKER)
    create_invalid_xml_response(TEST_CACHE_FILE_NAME)

    assert_emails 1 do
      weather.get_weather!
      assert File.exists?(GoogleWeather::RETRY_MARKER)
    end
    assert_equal ["c.zimmermann@kaupertmedia.de"], ActionMailer::Base.deliveries.first.to
  end

  test "should send email after marker file was deleted" do
    File.new(TEST_RETRY_MARKER, "w+").close
    GoogleWeather.redefine_const(:RETRY_TTL, 0); sleep 0.2
    stub_valid_xml_api_response!

    weather = GoogleWeather.new("Berlin", weather_options)
    assert File.exists?(GoogleWeather::RETRY_MARKER)
    create_invalid_xml_response(TEST_CACHE_FILE_NAME)

    assert_emails 1 do
      weather.get_weather!
      assert !File.exists?(GoogleWeather::RETRY_MARKER)
    end
    assert_equal ["c.zimmermann@kaupertmedia.de"], ActionMailer::Base.deliveries.last.to
  end

  test "should accept :lang as option" do
    weather = GoogleWeather.new("Berlin",weather_options(:lang => :es) )
    assert_equal "es", weather.lang
  end

  test "should calculate sunrise and sunset based on geodata" do
    weather = GoogleWeather.new("Berlin", weather_options(:geo_location => nil) )
    assert weather.respond_to? :sunrise
    assert weather.respond_to? :sunset
    assert_nil weather.sunrise
    assert_nil weather.sunset

    lat = 52.5163253260716
    lng = 13.3780860900879

    weather = GoogleWeather.new("Berlin", weather_options(:geodata => {:lat => lat, :lng => lng}) )
    assert weather.sunrise.is_a? Time
    assert weather.sunset.is_a? Time
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
    {:do_not_get_weather => true, :suppress_stderr_output => true, :cache_id => "test"}.merge(options.symbolize_keys!)
  end

end
