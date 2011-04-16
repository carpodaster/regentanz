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

    def create_invalid_xml_response(filename)
      File.open(filename, "w+") do |f|
        f.write '<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
  <TITLE>302 Moved</TITLE></HEAD><BODY>
  <H1>302 Moved</H1>
  The document has moved
  <A HREF="http://sorry.google.com/sorry/?continue=http://www.google.com/ig/api%3Fweather%3D86747%252CGermany%26hl%3Dde">here</A>.
  </BODY></HTML>
  '
      end
    end

    # Stub Net::HTTP.get_response to return a semi-dynamic (ie. current date) xml
    # response-
    def stub_valid_xml_api_response!
      xml_templ = ERB.new <<-EOF
  <?xml version="1.0"?>
  <xml_api_reply version="1">
      <weather module_id="0" tab_id="0" mobile_row="0" mobile_zipped="1" row="0" section="0" >
          <forecast_information>
              <city data="Berlin, Berlin"/><postal_code data=Berlin,Germany"/>
              <latitude_e6 data=""/>
              <longitude_e6 data=""/>
              <forecast_date data="<%= Date.today.strftime("%Y-%m-%d") %>"/>
              <current_date_time data="<%= 5.minutes.ago.utc.strftime("%Y-%m-%d %H:%M:00") %> +0000"/>
              <unit_system data="SI"/>
          </forecast_information>
          <current_conditions>
              <condition data="Klar"/><temp_f data="77"/>
              <temp_c data="25"/>
              <humidity data="Feuchtigkeit: 57 %"/>
              <icon data="/ig/images/weather/sunny.gif"/>
              <wind_condition data="Wind: W mit 24 km/h"/>
          </current_conditions>
          <forecast_conditions>
              <day_of_week data="Do."/><low data="16"/>
              <high data="31"/>
              <icon data="/ig/images/weather/chance_of_rain.gif"/>
              <condition data="Vereinzelt Regen"/>
          </forecast_conditions>
      </weather>
  </xml_api_reply>
  EOF
      mock_response = mock()
      mock_response.stubs(:body).returns(xml_templ.result)
      Net::HTTP.stubs(:get_response).returns(mock_response)
    end

  end

end

include Regentanz::TestHelper