require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class Regentanz::Cache::BaseTest < ActiveSupport::TestCase

  LINT_METHODS = [:available?, :add, :expire!, :valid?]

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


end