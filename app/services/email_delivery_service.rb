class EmailDeliveryService
  class DeliveryError < StandardError; end

  def self.deliver(email_log)
    new(email_log).deliver
  end

  def initialize(email_log)
    @email_log = email_log
  end

  def deliver
    EmailHubMailer.custom_email(email_log).deliver_now
    email_log.update!(status: "sent", error_message: nil)
  rescue StandardError => e
    email_log.update!(status: "failed", error_message: e.message.to_s.truncate(500))
    raise DeliveryError, e.message
  end

  private

  attr_reader :email_log
end
