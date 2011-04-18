require File.join(File.dirname(__FILE__), '..', 'test_helper')

class CallbacksTest < ActiveSupport::TestCase

  def setup
    @object = Object.new
    @object.extend Regentanz::Callbacks
  end

  def test_should_define_constant
    assert Regentanz::Callbacks::CALLBACKS
    expected_callbacks = [:api_failure_detected, :api_failure_resumed]
    assert_equal expected_callbacks, Regentanz::Callbacks::CALLBACKS
  end

  def test_google_weather_should_include_callbacks
    assert Regentanz::GoogleWeather.included_modules.include?(Regentanz::Callbacks)
    assert Regentanz::GoogleWeather.included_modules.include?(ActiveSupport::Callbacks)
  end

  def test_should_define_each_callback_method
    Regentanz::Callbacks::CALLBACKS.each do |callback_method|
      assert @object.private_methods.include?(callback_method.to_s), "#{callback_method} not defined"
    end
  end

end