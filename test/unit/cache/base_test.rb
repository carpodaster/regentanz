require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')
require 'digest/sha1'

class Regentanz::Cache::BaseTest < ActiveSupport::TestCase

  LINT_METHODS = [:available?, :expire!, :get, :set, :valid?]

  test "should define public interface for all cache backend" do
    obj = Regentanz::Cache::Base.new
    LINT_METHODS.each do |method|
      assert_respond_to obj, method
    end
  end

  test "should have check cache backend compatability via lint class method" do
    assert_respond_to Regentanz::Cache::Base, :lint

    obj = Object.new
    assert !Regentanz::Cache::Base.lint(obj)
    assert !Regentanz::Cache::Base.lint(Object)

    LINT_METHODS.each do |method|
      Object.any_instance.stubs(method)
    end
    assert Regentanz::Cache::Base.lint(obj)
    assert Regentanz::Cache::Base.lint(Object)
  end

  test "should have key sanitizer class method" do
    assert_respond_to Regentanz::Cache::Base, :sanitize_key
    key = Digest::SHA1.hexdigest("a test string")
    assert_equal key, Regentanz::Cache::Base.sanitize_key("a test string")

    assert_not_equal Regentanz::Cache::Base.sanitize_key("a test string"),
      Regentanz::Cache::Base.sanitize_key("another test string")
  end

  test "should inform about retry state" do
    obj = Regentanz::Cache::Base.new
    assert_respond_to obj, :waiting_for_retry?
  end

  test "should check if retry wait time is over" do
    obj = Regentanz::Cache::Base.new
    assert_respond_to obj, :unset_retry_state!
  end

  test "should enter retry state" do
    obj = Regentanz::Cache::Base.new
    assert_respond_to obj, :set_retry_state!
  end

end