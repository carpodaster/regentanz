module Regentanz
  module Conditions
    
    class Forecast < Regentanz::Conditions::Base

      attr_accessor :day_of_week, :high, :low

    end
  end
end