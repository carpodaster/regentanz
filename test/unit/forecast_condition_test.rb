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

end
