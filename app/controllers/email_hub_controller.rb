# app/controllers/email_hubs_controller.rb

class EmailHubController < ApplicationController
  before_action :authenticate_user!

  class CandidateOwnedByAnotherRecruiter < StandardError; end

  # def index
  #   @email_templates = email_templates
  #   @candidates = current_user.visible_candidates
  #                             .includes(:job, :recruiter)
  #                             .order(:name)
  #   @candidates_json = @candidates.map do |c|
  #     {
  #       id: c.id,
  #       name: c.name,
  #       email: c.email,
  #       role: c.role,
  #       ctc_expected: c.ctc_expected,
  #       job_title: c.job&.title,
  #       job_company: c.job&.company,
  #       recruiter_name: c.recruiter&.name,
  #       recruiter_email: c.recruiter&.email
  #     }
  #   end
  #   @email_logs = EmailLog.where(user: current_user)
  #                         .order(created_at: :desc)
  #                         .limit(100)
  # end

  def index
    case params[:tab]
    when "applications"
      load_applications
    when "sent"
      load_sent
    when "compose"
      load_compose
    else
      load_inbox
    end
  end

  # def send_email
  #   candidate = current_user.visible_candidates.find_by(id: params[:candidate_id]) if params[:candidate_id].present?

  #   email_log = EmailLog.new(
  #     user: current_user,
  #     candidate: candidate,
  #     template_name: params[:template_name].presence,
  #     subject: params[:subject],
  #     recipient_email: params[:to_email],
  #     cc_email: params[:cc],
  #     body: params[:body],
  #     status: "pending"
  #   )

  #   if email_log.save
  #     EmailDeliveryJob.perform_later(email_log.id)
  #     redirect_to email_hub_path, notice: "Email queued successfully."
  #   else
  #     redirect_to email_hub_path, alert: "Could not send email: #{email_log.errors.full_messages.to_sentence}"
  #   end
  # end

  def send_email
    candidate =
      current_user.visible_candidates.find_by(id: params[:candidate_id]) if params[:candidate_id].present?

    integration = GmailIntegration.recruitment.first

    result = GmailService.new(integration).send_new_email(
      to: params[:to_email],
      cc: params[:cc],
      subject: params[:subject],
      body: params[:body]
    )

    EmailMessage.create!(
      application: nil,
      candidate: candidate,
      message_id: result.fetch("id"),
      thread_id: result["threadId"],
      direction: "outgoing",
      status: "sent",
      from_email: integration.email,
      to_emails: params[:to_email],
      cc_emails: params[:cc],
      subject: params[:subject],
      body: params[:body],
      mailbox: integration.email,
      sent_at: Time.current
    )

    redirect_to email_hub_path(tab: "sent"),
                notice: "Email sent successfully."
  rescue => e
    Rails.logger.error(
      "Email send failed: #{e.class}: #{e.message}"
    )
    Rails.logger.error(e.backtrace.join("\n"))

    redirect_to email_hub_path(tab: "compose"),
                alert: "Could not send email. Please try again."
  end

  def clear_log
    EmailLog.where(user: current_user).delete_all

    redirect_to email_hub_path,
                notice: "Email log cleared."
  end

  # POST /email_hub/:thread_id/reject
  def reject_email
    messages = visible_inbox_thread!

    EmailMessage.transaction do
      locked_messages = messages.lock.to_a

      if locked_messages.empty? ||
        locked_messages.any? { |message| message.application_id.present? }
        raise ActiveRecord::RecordNotFound
      end

      EmailMessage.where(id: locked_messages.map(&:id))
                  .update_all(status: "rejected", updated_at: Time.current)
    end

    redirect_to email_hub_path(tab: "inbox"),
                notice: "Email conversation rejected successfully."
  rescue ActiveRecord::RecordNotFound
    redirect_to email_hub_path(tab: "inbox"),
                alert: "Email conversation not found or access denied."
  end

  # POST /email_hub/:thread_id/move_to_application
  def move_to_application
    messages = visible_inbox_thread!
    first_message = messages.first

    applicant_email = extract_applicant_email(first_message.from_email)

    if applicant_email.blank?
      redirect_to email_hub_path(tab: "inbox"),
                  alert: "Unable to identify the applicant's email address."
      return
    end

    normalized_email = applicant_email.downcase

    matched_jobs = EmailJobMatcher.new(first_message).matched_jobs

    job = matched_jobs.find do |matched_job|
      current_user.admin? ||
        matched_job.recruiters.exists?(id: current_user.id)
    end

    unless job
      redirect_to email_hub_path(tab: "inbox"),
                  alert: "No matching job opening was found for this recruiter."
      return
    end

    recruiter_id =
      if job.recruiters.exists?(id: current_user.id)
        current_user.id
      else
        job.recruiters.first&.id
      end

    unless recruiter_id
      redirect_to email_hub_path(tab: "inbox"),
                  alert: "No recruiter is assigned to the matching job."
      return
    end

    EmailMessage.transaction do
      locked_messages = messages.lock.to_a

      if locked_messages.empty? ||
        locked_messages.any? do |message|
          message.application_id.present? ||
            message.status == "rejected"
        end
        raise ActiveRecord::RecordNotFound
      end

      # Find the candidate without regard to case.
      candidate = Candidate.where(
        "LOWER(email) = ?",
        normalized_email
      ).first

      # Prevent using a candidate owned by another recruiter.
      if candidate.present? &&
        candidate.recruiter_id.present? &&
        candidate.recruiter_id != recruiter_id
        raise CandidateOwnedByAnotherRecruiter
      end

      unless candidate
        candidate = Candidate.create!(
          email: normalized_email,
          name: normalized_email.split("@").first,
          recruiter_id: recruiter_id,
          job_id: job.id,
          status: "New"
        )
      end

      application = Application.create!(
        candidate: candidate,
        job: job,
        status: "open",
        assigned_to_id: recruiter_id,
        source: "email",
        source_email: normalized_email,
        applied_at: Time.current
      )

      EmailMessage.where(id: locked_messages.map(&:id))
                  .update_all(
                    application_id: application.id,
                    updated_at: Time.current
                  )
    end

    redirect_to email_hub_path(tab: "applications"),
                notice: "Application created successfully."

  rescue CandidateOwnedByAnotherRecruiter
    redirect_to email_hub_path(tab: "inbox"),
                alert: "Can't move this email to a job application because this candidate already belongs to another recruiter."

  rescue ActiveRecord::RecordNotFound
    redirect_to email_hub_path(tab: "inbox"),
                alert: "Email conversation not found, already processed, or access denied."

  rescue ActiveRecord::RecordInvalid => e
    redirect_to email_hub_path(tab: "inbox"),
                alert: "Unable to create application: #{e.record.errors.full_messages.join(', ')}"
  end

  def reply
    body = params[:body].to_s.strip

    if body.blank?
      redirect_to email_hub_path(tab: "inbox"),
                  alert: "Reply cannot be empty."
      return
    end

    latest_message = find_reply_message

    unless latest_message
      redirect_to email_hub_path(tab: "inbox"),
                  alert: "Email conversation not found."
      return
    end

    if params[:application_id].present?
      application = Application.find(params[:application_id])

      unless current_user.admin? ||
            application.assigned_to_id == current_user.id
        redirect_to email_hub_path(tab: "applications"),
                    alert: "You are not authorized to reply to this application."
        return
      end
    end

    integration = GmailIntegration.recruitment.first

    result = GmailService.new(integration).send_reply(
      latest_message,
      body: body
    )

    EmailMessage.create!(
      application: latest_message.application,
      candidate: latest_message.candidate,
      message_id: result.fetch("id"),
      thread_id: result.fetch("threadId"),
      direction: "outgoing",
      status: "sent",
      from_email: integration.email,
      to_emails: latest_message.from_email,
      subject: reply_subject(latest_message.subject),
      body: body,
      mailbox: integration.email,
      sent_at: Time.current
    )

    if params[:application_id].present?
      redirect_to application_path(params[:application_id]),
                  notice: "Reply sent successfully."
    else
      redirect_to email_hub_path(
                    tab: "inbox",
                    thread_id: latest_message.thread_id
                  ),
                  notice: "Reply sent successfully."
    end
  end

  def download_attachment
    mailbox = ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com")

    message = EmailMessage.find_by(id: params[:message_id])

    unless message
      Rails.logger.error("404: EmailMessage not found: #{params[:message_id]}")
      head :not_found
      return
    end

    unless message.mailbox == mailbox && message.direction == "incoming"
      Rails.logger.error("404: Message mailbox or direction does not match")
      head :not_found
      return
    end

    integration = GmailIntegration.recruitment.first

    unless integration
      Rails.logger.error("Gmail integration not found")
      head :service_unavailable
      return
    end

    gmail = GmailService.new(integration)
    attachments = gmail.list_attachments(message.message_id)
    index = Integer(params[:attachment_index], exception: false)

    unless index && index >= 0 && index < attachments.length
      head :not_found
      return
    end

    attachment = attachments[index]

    unless attachment[:attachment_id].present?
      head :not_found
      return
    end

    result = gmail.get_attachment(
      message.message_id,
      attachment[:attachment_id]
    )

    file_data = result.data.to_s
    filename = File.basename(attachment[:filename].to_s)
    filename = "attachment" if filename.blank? || filename == "."

    send_data file_data,
              filename: filename,
              type: attachment[:mime_type].presence ||
                    "application/octet-stream",
              disposition: "attachment"
  end

  private

  def email_templates
    EmailTemplate.active.order(:name).map do |template|
    {
      id: template.id.to_s,
      name: template.name,
      subject: template.subject,
      body: template.body
    }
    end
  end

  def load_compose
    @email_templates = email_templates

    @candidates = current_user.visible_candidates
                              .includes(:job, :recruiter)
                              .order(:name)

    @candidates_json = @candidates.map do |c|
      {
        id: c.id,
        name: c.name,
        email: c.email,
        role: c.role,
        ctc_expected: c.ctc_expected,
        job_title: c.job&.title,
        job_company: c.job&.company,
        recruiter_name: c.recruiter&.name,
        recruiter_email: c.recruiter&.email
      }
    end
  end

  def load_sent
    mailbox = ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com")

    @email_messages = EmailMessage
                        .where(
                          mailbox: mailbox,
                          direction: "outgoing"
                        )
                        .includes(:candidate, :application)
                        .order(sent_at: :desc, created_at: :desc)
                        .limit(200)

    @selected_message =
      if params[:message_id].present?
        @email_messages.find_by(id: params[:message_id])
      end
  end

  def load_inbox
    mailbox = ENV.fetch(
      "RECRUITMENT_MAILBOX",
      "jobs@spritle.com"
    )

    @candidates = current_user.visible_candidates
                              .includes(:job, :recruiter)
                              .order(:name)

    incoming_messages = EmailMessage
      .where(
        mailbox: mailbox,
        direction: "incoming",
        status: "received",
        application_id: nil
      )
      .includes(:candidate, :application)
      .order(received_at: :desc, created_at: :desc)
      .limit(200)

    if current_user.admin?
      @email_messages = incoming_messages
    else
      @email_messages = incoming_messages.select do |message|
        EmailJobMatcher.new(message).matched_jobs.any? do |job|
          job.recruiters.exists?(id: current_user.id)
        end
      end
    end

    @thread_groups = @email_messages.group_by(&:thread_id)

    @selected_thread_id = params[:thread_id]

    @selected_messages =
      if @selected_thread_id.present?
        EmailMessage
          .where(
            mailbox: mailbox,
            thread_id: @selected_thread_id,
            direction: "incoming"
          )
          .includes(:candidate, :application)
          .order(received_at: :asc, created_at: :asc)
      else
        EmailMessage.none
      end

    @selected_candidate = @selected_messages
                            .map(&:candidate)
                            .compact
                            .first

    @selected_application = @selected_messages
                              .map(&:application)
                              .compact
                              .first

    # NEW: Fetch attachment metadata for the selected conversation only.
    @selected_message_attachments = {}

    if @selected_messages.exists?
      integration = GmailIntegration.recruitment.first

      if integration
        gmail = GmailService.new(integration)

        @selected_messages.each do |message|
          @selected_message_attachments[message.id] =
            gmail.list_attachments(message.message_id)
        end
      end
    end

    @pending_email_count = if @email_messages.is_a?(ActiveRecord::Relation)
                         @email_messages.where(status: "received").count
                       else
                         @email_messages.count { |message| message.status == "received" }
                       end

    @jobs = current_user.visible_jobs.order(:title)
  end

  def load_applications
    scope = Application
            .where.not(candidate_id: nil, job_id: nil)
            .includes(:candidate, :job, :assigned_to)
            .order(created_at: :desc)

    if current_user.admin?
      @applications = scope
    else
      @applications = scope.where(assigned_to_id: current_user.id)
    end

    @pending_application_count = @applications.where(status: "open").count
    @jobs = current_user.visible_jobs.order(:title)
  end

  def find_reply_message
    if params[:application_id].present?
      # Reply from Application details
      EmailMessage
        .where(
          application_id: params[:application_id],
          direction: "incoming"
        )
        .order(
          Arel.sql(
            "COALESCE(received_at, created_at) DESC"
          )
        )
        .first

    elsif params[:thread_id].present?
      # Reply from Inbox
      EmailMessage
        .where(
          thread_id: params[:thread_id],
          direction: "incoming"
        )
        .order(
          Arel.sql(
            "COALESCE(received_at, created_at) DESC"
          )
        )
        .first
    end
  end

  def reply_subject(subject)
    subject.to_s.start_with?("Re:") ? subject : "Re: #{subject}"
  end

  def visible_inbox_thread!
    thread_id = params[:thread_id].to_s

    raise ActiveRecord::RecordNotFound if thread_id.blank?

    messages = EmailMessage.where(
      mailbox: ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com"),
      thread_id: thread_id,
      direction: "incoming"
    ).order(received_at: :asc, created_at: :asc)

    raise ActiveRecord::RecordNotFound if messages.empty?

    # Do not allow actions on conversations already converted or rejected.
    if messages.any? do |message|
        message.application_id.present? || message.status == "rejected"
      end
      raise ActiveRecord::RecordNotFound
    end

    unless current_user.admin?
      visible_to_recruiter = messages.any? do |message|
        EmailJobMatcher.new(message).matched_jobs.any? do |job|
          job.recruiters.exists?(id: current_user.id)
        end
      end

      raise ActiveRecord::RecordNotFound unless visible_to_recruiter
    end

    messages
  end

  def extract_applicant_email(from_email)
    from_email.to_s[/[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}/i]
  end
end