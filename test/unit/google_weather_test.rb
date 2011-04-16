require File.join(File.dirname(__FILE__), '..', 'test_helper')

class GoogleWeatherTest < ActiveSupport::TestCase

  TEST_CACHE_FILE_NAME = File.join(Regentanz.configuration.cache_dir, "regentanz_test.xml")

  def setup
    # FIXME Remove ActionMailer
    ActionMailer::Base.deliveries.clear
    setup_regentanz_test_configuration!
  end

  def teardown
    Dir.glob(File.join(Regentanz.configuration.cache_dir, "**", "*")).each { |file| File.delete(file) }
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

  test "should have cache instance" do
    obj = Factory(:google_weather)
    assert_respond_to obj, :cache
    assert_kind_of Regentanz.configuration.cache_backend, obj.cache
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

  test "should remove retry marker and invalid cache file when retry_ttl waittime is over" do
    File.new(Regentanz.configuration.retry_marker, "w+").close
    assert File.exists?(Regentanz.configuration.retry_marker) # ensure test setup
    Regentanz.configuration.retry_ttl = 0; sleep 0.1
    Regentanz::GoogleWeather.any_instance.expects(:after_api_failure_resumed) # callback

    create_invalid_xml_response(TEST_CACHE_FILE_NAME)
    weather = Factory(:google_weather)

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

  test "should set default cache_id by location" do
    obj = Regentanz::GoogleWeather.new(:location => "Test Valley", :cache_id => nil)
    assert_not_nil obj.cache_id
  end

  private

  # Return a few default options for the test environment
  def weather_options(options = {})
    {:cache_id => "test"}.merge(options.symbolize_keys!)
  end

end
