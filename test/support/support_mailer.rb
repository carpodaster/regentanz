class SupportMailer

  def self.deliver_weather_retry_marker_notification!(weather_obj, mode)
    ActionMailer::Base.deliveries << "fake mail"
  end
  
end