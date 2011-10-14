module Regentanz
  module Parser
    class GoogleWeather
      require 'iconv'

      XML_ENCODING = 'LATIN1' # source encoding of the XML data

      # Converts a string from XML_ENCODING to UTF-8 using the Iconv library.
      #
      # === Note
      # FIXME The XML source document seems to be delivered LATIN1 or UTF-8, completely
      # random and unpredictable.
      #
      # === Parameters
      # * +data+: string to convert
      def convert_encoding data
        return if data.blank?
        self.class::XML_ENCODING != "UTF-8" ? Iconv.iconv("UTF-8", self.class::XML_ENCODING, data).flatten.join(" ") : data
      end

      def parse_current!(xml)
        return if xml.blank?
        begin
          doc = REXML::Document.new(xml)
          if doc.elements['xml_api_reply/weather/current_conditions']
            attributes = {}
            doc.elements['xml_api_reply/weather/current_conditions'].each_element do |ele|
              attributes.merge! parse_node(ele)
            end
            Regentanz::Conditions::Current.new(attributes)
          end
        rescue
          # FIXME should report error
        end
      end

      def parse_forecast!(xml)
        return if xml.blank?
        forecasts = []
        begin
          doc = REXML::Document.new(xml)
          if doc.elements['xml_api_reply/weather/forecast_conditions']
            attributes = {}
            doc.elements['xml_api_reply/weather/forecast_conditions'].each_element do |ele|
              attributes.merge! parse_node(ele)
            end
            forecasts << Regentanz::Conditions::Forecast.new(attributes)
          end
          forecasts
        rescue
          # FIXME should report error
        end
      end

      #private # FIXME private methods should start here after parse! has been implemented

      # Handles some special treatment for certain sub-elements, transforms _element_
      # into a hash and returns it.
      #
      # === Parameters
      # * +element+ childnode of type REXML::Element
      def parse_node(element)
        hash = {}
        hash.merge! parse_style(element.attribute("data").to_s) if element.name == "icon"
        if element.name == "humidity"
          # Handle the small whitespace just before the '%'
          hash.merge! element.name => element.attribute("data").to_s.gsub(/(\d+).+%$/, '\1 %')
        elsif element.name == "icon"
          # We want the full URL
          hash.merge! element.name => "http://www.google.com" + element.attribute("data").to_s
        elsif (element.name == "high" or element.name == "low") and @lang == "en"
          # Forecast-temperatures in EN are listed in °F; we fix that here
          temp_f = element.attribute("data").to_s.to_i
          hash.merge! element.name => ( temp_f - 32 ) * 5 / 9
        else
          hash.merge! element.name => element.attribute("data").to_s
        end
        hash
      end

      private

      # Extracts a name for the weather condition from the icon name. Intended to
      # be used as CSS style class name.
      #
      # === Parameters
      # * +path+ an URI-string to Google's weather icon
      def parse_style(path)
        hash = {}
        unless path.blank?
          style = File.basename(path) # FIXME is this what we want for everyone?
          style = style.slice(0, style.rindex(".")).gsub(/_/, '-')
          hash = { "style" => style }
        end
        hash
      end

    end
  end
end
