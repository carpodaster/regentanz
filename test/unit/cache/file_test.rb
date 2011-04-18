require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class Regentanz::Cache::FileTest < ActiveSupport::TestCase

  def setup
    setup_regentanz_test_configuration!
  end

  def teardown
    Dir.glob(File.join(Regentanz.configuration.cache_dir, "**", "*")).each { |file| File.unlink(file) }
  end

  test "should not fail lint" do
    assert Regentanz::Cache::Base.lint(Regentanz::Cache::File)
    assert Regentanz::Cache::Base.lint(Regentanz::Cache::File.new)
  end

  test "should return filename for key" do
    obj = Regentanz::Cache::File.new
    assert_respond_to obj, :filename
    filename = File.join(Regentanz.configuration.cache_dir, "regentanz_test.xml")
    assert_equal filename, obj.filename("test")
  end

  test "should create cache file" do
    obj = Regentanz::Cache::File.new
    assert !File.exists?(obj.filename("test"))
    assert obj.set("test", "some cache values")
    assert File.exists?(obj.filename("test"))
  end

  test "should rescue set from saving errors" do
    File.expects(:open).raises(SystemCallError, "pretend something went wrong")
    obj = Regentanz::Cache::File.new
    assert_nothing_raised do
      assert !obj.set("test", "some cache values")
    end
  end

  test "available?" do
    obj = Regentanz::Cache::File.new
    assert !obj.available?("test")

    File.new(obj.filename("test"), "w+").close
    assert obj.available?("test")
  end

  test "should delete file after expire" do
    obj = Regentanz::Cache::File.new
    assert !obj.expire!("test") # nothing to expire, return false

    File.new(obj.filename("test"), "w+").close
    assert obj.expire!("test")
    assert !File.exists?(obj.filename("test"))
  end

  test "should rescue expire from saving errors" do
    File.expects(:delete).raises(SystemCallError, "pretend something went wrong").once
    obj = Regentanz::Cache::File.new
    assert_nothing_raised do
      File.new(obj.filename("test"), "w+").close
      assert !obj.expire!("test")
    end
  end

  test "should get contents from file" do
    obj = Regentanz::Cache::File.new

    File.open(obj.filename('test_get'), 'w+') {|file| file.print "cached data" }
    assert obj.available?('test_get')
    assert_equal "cached data", obj.get('test_get')
    # cache not available, return false
    assert_nil obj.get("does not exist")
  end

  test "should rescue get from reading errors" do
    obj = Regentanz::Cache::File.new
    File.open(obj.filename('test'), 'w+') {|file| file.print "cached data" }
    File.expects(:open).raises(SystemCallError, "pretend something went wrong").once

    assert_nothing_raised do
      assert !obj.get("test")
    end
  end

  test "should check validity" do
    obj = Regentanz::Cache::File.new
    assert !obj.valid?('test')
    File.open(obj.filename('test'), 'w+') { |file| file.puts valid_xml_response }

    # valid_xml_response contains current datestamp,
    # so should be valid on all fronts
    assert obj.valid?('test')

    # Pretend the file is too old
    Regentanz.configuration.cache_ttl = 0
    assert !obj.valid?('test')
  end
  
  test "should rescue valid from REXML errors" do
    obj = Regentanz::Cache::File.new
    File.open(obj.filename('test'), 'w+') { |file| file.puts invalid_xml_response }
    REXML::Document.expects(:new).raises(REXML::ParseException, "pretend something went wrong")

    assert_nothing_raised do
      assert !obj.valid?('test')
    end
  end

  # ##############################
  # Retry-state tests
  # ##############################

  test "should inform about retry state" do
    obj = Regentanz::Cache::File.new
    assert !obj.waiting_for_retry?

    File.expects(:exists?).with(Regentanz.configuration.retry_marker).returns(true)
    assert obj.waiting_for_retry?
  end

  test "should check if retry wait time is over" do
    obj = Regentanz::Cache::File.new
    File.new(Regentanz.configuration.retry_marker, "w+").close
    Regentanz.configuration.retry_ttl = 1000.hours.to_i # something incredibly high to warrant retry state
    assert !obj.unset_retry_state! # not waited long enough

    Regentanz.configuration.retry_ttl = 0
    assert obj.unset_retry_state!
    assert !File.exists?(Regentanz.configuration.retry_marker)
  end

  test "should enter retry state" do
    obj = Regentanz::Cache::File.new
    assert !File.exists?(Regentanz.configuration.retry_marker)
    assert obj.set_retry_state!
    assert obj.set_retry_state! # subsequent calls return the same
    assert File.exists?(Regentanz.configuration.retry_marker)
  end

end