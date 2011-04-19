module Regentanz
  module Conditions
    class Base

      attr_accessor :condition, :style, :icon

      def initialize(attributes = {})
        attributes.symbolize_keys!
        attributes.keys.each do |attr|
          self.send(:"#{attr}=", attributes[attr]) if respond_to?(:"#{attr}=")
        end
      end
      
    end
  end
end