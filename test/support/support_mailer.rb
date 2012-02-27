class SupportMailer

  def self.weather_retry_marker_notification(weather_obj, mode)
    DeliveryStub.new(weather_obj, mode)
  end

  class DeliveryStub
    def initialize(*args)
    end

    def deliver!
      ActionMailer::Base.deliveries << "fake mail"
    end
  end

end
