module Regentanz
  module Conditions
    
    class Current < Regentanz::Conditions::Base

      attr_reader   :temp_c, :temp_f
      attr_accessor :humidity, :wind_condition

      def temp_c=temp; @temp_c = temp.to_i; end
      def temp_f=temp; @temp_f = temp.to_i; end

    end
  end
end