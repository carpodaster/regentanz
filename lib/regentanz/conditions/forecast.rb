module Regentanz
  module Conditions
    
    class Forecast < Regentanz::Conditions::Base

      attr_reader   :high, :low
      attr_accessor :day_of_week

      def high=temp; @high = temp.to_i; end
      def low=temp; @low = temp.to_i; end

    end
  end
end