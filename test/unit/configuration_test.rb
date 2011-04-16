require File.join(File.dirname(__FILE__), '..', 'test_helper')
require "tmpdir"

class ConfigurationTest < ActiveSupport::TestCase

  test "should configure Regentanz" do
    assert_respond_to Regentanz, :configure
    assert_respond_to Regentanz, :configuration
    assert_not_nil Regentanz.configuration

    Regentanz.configure do |config|
      config.do_not_get_weather = true
    end
    assert_not_nil Regentanz.configuration
    assert Regentanz.configuration.do_not_get_weather
  end

  test "should have configuration" do
    configuration_options = [
      :base_url,
      :cache_backend,
      :cache_dir,
      :cache_prefix,
      :cache_ttl,
      :retry_marker,
      :retry_ttl,
      :do_not_get_weather,
      :suppress_stderr_output
    ]
    assert_equal configuration_options, Regentanz::Configuration::OPTIONS, "Diff: #{configuration_options - Regentanz::Configuration::OPTIONS}"
    obj = Regentanz::Configuration.new
    configuration_options.each do |config_option|
      assert_respond_to obj, config_option
    end
  end

  test "every DEFAULT_OPTION should have a cattr_accessor" do
    assert_not_nil Regentanz::Configuration::DEFAULT_OPTIONS
    Regentanz::Configuration::DEFAULT_OPTIONS.each do |config_option|
      assert_respond_to Regentanz::Configuration, :"default_#{config_option}"
      assert_not_nil    Regentanz::Configuration.send(:"default_#{config_option}")
    end

  end

  test "instance should have sane defaults" do
    obj = Regentanz::Configuration.new
    tmpdir = Dir.tmpdir
    assert_equal "http://www.google.com/ig/api",               obj.base_url
    assert_equal "#{tmpdir}",                                  obj.cache_dir
    assert_equal "regentanz",                                  obj.cache_prefix
    assert_equal 14400,                                        obj.cache_ttl
    assert_equal 3600,                                         obj.retry_ttl
    assert_equal "#{tmpdir}/regentanz_api_retry.txt",          obj.retry_marker
  end

end