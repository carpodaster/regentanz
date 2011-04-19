require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ForecastConditionTest < ActiveSupport::TestCase
  
  def setup
    @object = Regentanz::Conditions::Forecast.new
  end

  test "should define setters and getters" do
    [:condition, :style, :icon, :day_of_week, :high, :low].each do |attr|
      assert_respond_to @object, attr
      assert_respond_to @object, :"#{attr}="
    end
  end

  test "should initialize with attributes hash" do
    attributes = {
      "high"        => "31",
      "condition"   => "Vereinzelt Regen",
      "icon"        => "http://www.google.com/ig/images/weather/chance_of_rain.gif",
      "day_of_week" =>"Do.",
      "low"         => "16",
      "style"       => "chance-of-rain"
    }

    obj = Regentanz::Conditions::Forecast.new(attributes)
    assert_equal 31, obj.high
    assert_equal "Vereinzelt Regen", obj.condition
    assert_equal "http://www.google.com/ig/images/weather/chance_of_rain.gif", obj.icon
    assert_equal "Do.", obj.day_of_week
    assert_equal 16, obj.low
    assert_equal "chance-of-rain", obj.style
  end

end
