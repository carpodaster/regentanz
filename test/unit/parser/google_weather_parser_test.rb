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

  test "should parse xml" do
    obj = Regentanz::Parser::GoogleWeather.new
    assert_respond_to obj, :parse!
    assert_nil obj.parse!(nil)
    assert_nil obj.parse!("")
    # FIXME test actual conversion
    flunk
  end
  
end