module Regentanz
  module Callbacks

    CALLBACKS = %w(after_api_failure_detected after_api_failure_resumed)

    CALLBACKS.each do |callback_method|
      # Define no-op stubs for all CALLBACKS
      define_method(callback_method) {}
      private callback_method
    end

    def self.included(base)
      base.send :include, ActiveSupport::Callbacks
      base.define_callbacks *CALLBACKS
    end
    
  end
end