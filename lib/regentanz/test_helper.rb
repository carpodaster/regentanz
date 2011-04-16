module Regentanz
  module TestHelper

    # Default values used for testing. Use this in your setup methods.
    # Configuration values can be overriden by supplying a block. See
    # Regentanz::Configuration for supported values.
    def setup_regentanz_test_configuration!
      Regentanz.configure do |config|
        config.retry_ttl              = Regentanz::Configuration.default_cache_ttl
        config.do_not_get_weather     = true
        config.retry_ttl              = Regentanz::Configuration.default_retry_ttl
        config.suppress_stderr_output = true
        yield config if block_given? # add settings or override above from client
      end
    end

    # Returns an invalid API response that will cause REXML to hickup
    def invalid_xml_response
      '<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">' \
      "<TITLE>302 Moved</TITLE></HEAD><BODY>\n" \
      "<H1>302 Moved</H1>\n" \
      "The document has moved\n" \
      '<A HREF="http://sorry.google.com/sorry/?continue=http://www.google.com/ig/api%3Fweather%3D86747%252CGermany%26hl%3Dde">here</A>' \
      "</BODY></HTML>\n"
    end

    # Returns a valid xml api reply based upon ./test/support/valid_response.xml.erb
    def valid_xml_response
      filename = File.join(Regentanz.configuration.cache_dir, '..', 'valid_response.xml.erb')
      xmlerb = ERB.new(File.open(filename, 'r') { |file| file.read })
      xmlerb.result
    end

    # Creates a cache file +filename+ with contents of #invalid_xml_response
    # FIXME this is deprecated with the introduction of Regentanz::Cache::File
    def create_invalid_xml_response(filename)
      File.open(filename, "w+") { |f| f.puts invalid_xml_response }
    end

    # Stub Net::HTTP.get_response to return a semi-dynamic (ie. current date) xml
    # response-
    def stub_valid_xml_api_response!
      mock_response = mock()
      mock_response.stubs(:body).returns(valid_xml_response)
      Net::HTTP.stubs(:get_response).returns(mock_response)
    end

  end

end

include Regentanz::TestHelper