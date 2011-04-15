require File.join(File.dirname(__FILE__), '..', 'test_helper')

class AstronomyTest < Test::Unit::TestCase

  def setup
    @object = Object.new
    @object.extend Regentanz::Astronomy
  end

  def test_google_weather_should_include_astronomy
    assert Regentanz::GoogleWeather.included_modules.include?(Regentanz::Astronomy)
  end

  def test_deg_to_rad
    assert Regentanz::Astronomy.private_instance_methods.include?("deg_to_rad")
    degrees = 42
    assert_equal degrees*Math::PI/180, @object.send(:deg_to_rad, degrees)
  end

  def test_rad_to_deg
    assert Regentanz::Astronomy.private_instance_methods.include?("rad_to_deg")
    radians = 42
    assert_equal radians*180/Math::PI, @object.send(:rad_to_deg, radians)
  end
  
end