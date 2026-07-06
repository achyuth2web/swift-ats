class EmailDeliveryJob < ApplicationJob
  queue_as :mailers

  retry_on EmailDeliveryService::DeliveryError, wait: :polynomially_longer, attempts: 3

  def perform(email_log_id)
    email_log = EmailLog.find(email_log_id)
    EmailDeliveryService.deliver(email_log)
  end
end
