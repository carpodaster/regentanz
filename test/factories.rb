module Regentanz
  module Test
    Factory.define :google_weather, :class => Regentanz::GoogleWeather, :default_strategy => :build do |f|
      f.location "Testhausen"
      f.cache_id "test"
    end
  end
end
