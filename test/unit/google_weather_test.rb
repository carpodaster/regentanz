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

  test "should enter retry state and send email if invalid xml file has been found" do
    stub_valid_xml_api_response!
    Regentanz::GoogleWeather.any_instance.expects(:api_failure_detected) # callback

    weather = Factory(:google_weather)
    assert !weather.waiting_for_retry?
    create_invalid_xml_response(TEST_CACHE_FILE_NAME)

    assert_emails 1 do
      weather.get_weather!
      assert weather.waiting_for_retry?
    end
  end

  test "should leave retry state remove invalid cache file when retry_ttl waittime is over" do
    File.new(Regentanz.configuration.retry_marker, "w+").close
    assert File.exists?(Regentanz.configuration.retry_marker) # ensure test setup
    Regentanz.configuration.retry_ttl = 0; sleep 0.1
    Regentanz::GoogleWeather.any_instance.expects(:api_failure_resumed) # callback

    create_invalid_xml_response(TEST_CACHE_FILE_NAME)
    weather = Factory(:google_weather)

    assert_emails 1 do
      weather.get_weather!
      assert !weather.waiting_for_retry?
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

  test "should work with caching disabled" do
    Regentanz.configuration.cache_backend = nil
    stub_valid_xml_api_response!
    obj = Factory(:google_weather, :cache_id => nil)
    assert_nil obj.cache
    obj.get_weather!
  end

  test "should delegate retry state to cache instance" do
    obj = Factory(:google_weather)
    assert_respond_to obj, :waiting_for_retry?
    assert_not_nil obj.cache
    assert !obj.waiting_for_retry?
    obj.cache.expects(:waiting_for_retry?).returns(true)
    assert obj.waiting_for_retry?
  end

  test "should respond_to present?" do
    obj = Factory(:google_weather)
    assert_respond_to obj, :present?

    Regentanz::GoogleWeather.any_instance.expects(:current).returns(nil)
    Regentanz::GoogleWeather.any_instance.expects(:forecast).returns(nil)
    assert_equal false, obj.present?

    Regentanz::GoogleWeather.any_instance.expects(:current).returns(nil)
    Regentanz::GoogleWeather.any_instance.expects(:forecast).returns(true)
    assert_equal true, obj.present?
    Regentanz::GoogleWeather.any_instance.expects(:current).returns(true)
    assert_equal true, obj.present?
  end

  private

  # Return a few default options for the test environment
  def weather_options(options = {})
    {:cache_id => "test"}.merge(options.symbolize_keys!)
  end

end
