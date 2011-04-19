require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class GoogleWeatherParserTest < ActiveSupport::TestCase

  def setup
    setup_regentanz_test_configuration!
  end

  test "should have parser instance" do
    obj = Regentanz::GoogleWeather.new
    assert_respond_to obj, :parser
    assert_not_nil obj.parser
    assert_kind_of Regentanz::Parser::GoogleWeather, obj.parser
  end

  test "should convert encoding" do
    obj = Regentanz::Parser::GoogleWeather.new
    assert_respond_to obj, :convert_encoding
    assert_nil obj.convert_encoding(nil)
    assert_nil obj.convert_encoding("")
    # FIXME test actual conversion
  end

  test "should parse xml for current condition" do
    obj = Regentanz::Parser::GoogleWeather.new
    assert_respond_to obj, :parse_current!
    assert_nil obj.parse_current!(nil)
    assert_nil obj.parse_current!("")

    xml = valid_xml_response
    parsed = obj.parse_current!(xml)
    assert_kind_of Regentanz::Conditions::Current, parsed
    assert_equal "Feuchtigkeit: 57 %", parsed.humidity
    assert_equal "Wind: W mit 24 km/h", parsed.wind_condition
    assert_equal 25, parsed.temp_c
    assert_equal 77, parsed.temp_f
    assert_equal "http://www.google.com/ig/images/weather/sunny.gif", parsed.icon
    assert_equal "Klar", parsed.condition
  end

  test "should rescue current condition parsing from parse erros" do
    obj = Regentanz::Parser::GoogleWeather.new
    xml = invalid_xml_response
    assert_nothing_raised { assert_nil obj.parse_current!(xml) }
  end

  test "should parse xml for forecast" do
    obj = Regentanz::Parser::GoogleWeather.new
    assert_respond_to obj, :parse_forecast!
    assert_nil obj.parse_forecast!(nil)
    assert_nil obj.parse_forecast!("")

    xml = valid_xml_response
    parsed = obj.parse_forecast!(xml)
    assert_kind_of Array, parsed
    assert_equal 1, parsed.size
    assert_kind_of Regentanz::Conditions::Forecast, parsed.first
    assert_equal "Do.", parsed.first.day_of_week
    assert_equal 31, parsed.first.high
    assert_equal 16, parsed.first.low
    assert_equal "http://www.google.com/ig/images/weather/chance_of_rain.gif", parsed.first.icon
    assert_equal "Vereinzelt Regen", parsed.first.condition
  end
  
  test "should rescue forecast parsing from parse erros" do
    obj = Regentanz::Parser::GoogleWeather.new
    xml = invalid_xml_response
    assert_nothing_raised { assert_nil obj.parse_forecast!(xml) }
  end

end