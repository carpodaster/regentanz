require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class Regentanz::Cache::FileTest < ActiveSupport::TestCase

  test "should not fail lint" do
    assert Regentanz::Cache::Base.lint(Regentanz::Cache::File)
    assert Regentanz::Cache::Base.lint(Regentanz::Cache::File.new)
  end


end