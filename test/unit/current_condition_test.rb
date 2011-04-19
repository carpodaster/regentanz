require File.join(File.dirname(__FILE__), '..', 'test_helper')

class CurrentConditionTest < ActiveSupport::TestCase
  
  test "should define setters and getters" do
    obj = Regentanz::Conditions::Current.new
    [:condition, :style, :icon, :humidity, :wind_condition, :temp_c, :temp_f].each do |attr|
      assert_respond_to obj, attr
      assert_respond_to obj, :"#{attr}="
    end
  end

  test "should initialize with attributes hash" do
    attributes = {
      "condition"      => "Klar",
      "temp_f"         => "77",
      "temp_c"         => "25",
      "humidity"       => "Feuchtigkeit: 57 %",
      "icon"           => "http://www.google.com/ig/images/weather/sunny.gif",
      "style"          => "sunny",
      "wind_condition" => "Wind: W mit 24 km/h"
    }
    obj = Regentanz::Conditions::Current.new(attributes)
    assert_equal "Klar", obj.condition
    assert_equal 77, obj.temp_f
    assert_equal 25, obj.temp_c
    assert_equal "Feuchtigkeit: 57 %", obj.humidity
    assert_equal "http://www.google.com/ig/images/weather/sunny.gif", obj.icon
    assert_equal "sunny", obj.style
    assert_equal "Wind: W mit 24 km/h", obj.wind_condition
  end

end
