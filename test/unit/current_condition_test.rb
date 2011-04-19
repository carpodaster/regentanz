require File.join(File.dirname(__FILE__), '..', 'test_helper')

class CurrentConditionTest < ActiveSupport::TestCase
  
  def setup
    @object = Regentanz::Conditions::Current.new
  end

  test "should define setters and getters" do
    [:condition, :style, :icon, :humidity, :wind_condition, :temp_c, :temp_f].each do |attr|
      assert_respond_to @object, attr
      assert_respond_to @object, :"#{attr}="
    end
  end

end
