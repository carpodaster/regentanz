module Regentanz
  module Conditions
    
    class Current < Regentanz::Conditions::Base

      attr_accessor :humidity, :wind_condition, :temp_c, :temp_f

    end
  end
end