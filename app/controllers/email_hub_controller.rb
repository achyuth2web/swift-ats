# app/controllers/email_hubs_controller.rb

class EmailHubController < ApplicationController
  before_action :authenticate_user!

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
      if current_user.admin?
        load_inbox
      else
        redirect_to email_hub_path(tab: "applications")
        return
      end
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

  def confirm_application
    thread_id = params[:thread_id]

    messages = EmailMessage
                .where(
                  mailbox: ENV.fetch(
                    "RECRUITMENT_MAILBOX",
                    "jobs@spritle.com"
                  ),
                  thread_id: thread_id
                )
                .order(received_at: :asc, created_at: :asc)

    if messages.empty?
      redirect_to email_hub_path(tab: "inbox"),
                  alert: "Email conversation not found."
      return
    end

    candidate = Candidate.find(params[:candidate_id])
    job = Job.find(params[:job_id])

    application = Application.create!(
      candidate: candidate,
      job: job,
      status: "open",
      assigned_to_id: nil,
      source: "email",
      source_email: messages.first.from_email,
      applied_at: Time.current
    )

    messages.update_all(application_id: application.id)

    redirect_to email_hub_path(
      tab: "inbox",
      thread_id: thread_id
    ), notice: "Application created successfully."
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

  private

  def email_templates
    [
      {
        id:'interview-invite',
        name:'Interview Invitation',
        subject:'Interview Invitation — {role} at {company}',
        body:"Dear {name},\n\nThank you for applying for the {role} position at {company}.\n\nWe are pleased to invite you for an interview on {date} at {time}.\n\nDetails:\n- Role: {role}\n- Interviewer: {interviewer}\n- Mode: {mode}\n- Location/Link: {location}\n\nPlease confirm your availability by replying to this email.\n\nBest regards,\n{recruiter}\n{company}"
      },
      {
        id:'offer-letter',
        name:'Offer Letter',
        subject:'Offer Letter — {role} at {company}',
        body:"Dear {name},\n\nWe are delighted to offer you the position of {role} at {company}.\n\nOffer Details:\n- Role: {role}\n- CTC: {ctc} LPA\n- Joining Date: {date}\n- Location: {location}\n\nKindly sign and return this offer within 3 working days to confirm your acceptance.\n\nWelcome to the team!\n\nWarm regards,\n{recruiter}\n{company}"
      },
      {
        id:'rejection',
        name:'Rejection (Polite)',
        subject:'Update on your application — {role}',
        body:"Dear {name},\n\nThank you for your time and interest in the {role} position at {company}.\n\nAfter careful consideration, we have decided to move forward with other candidates whose experience more closely matches our current requirements.\n\nWe truly appreciate the effort you put into the process and encourage you to apply for future openings that align with your profile.\n\nWishing you all the best.\n\nSincerely,\n{recruiter}\n{company}"
      },
      {
        id:'shortlist',
        name:'Shortlist Notification',
        subject:'Good news — you have been shortlisted for {role}',
        body:"Dear {name},\n\nWe are pleased to inform you that you have been shortlisted for the {role} position at {company}.\n\nNext steps will be communicated to you shortly. In the meantime, feel free to reach out if you have any questions.\n\nBest regards,\n{recruiter}\n{company}"
      },
      {
        id:'follow-up',
        name:'Follow-up / Status Check',
        subject:'Following up — {role} application',
        body:"Dear {name},\n\nI hope you are doing well. I wanted to follow up regarding your application for the {role} position at {company}.\n\nWe are currently in the evaluation phase and expect to get back to you by {date}.\n\nThank you for your patience.\n\nBest,\n{recruiter}\n{company}"
      }
    ]
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

    @email_messages = EmailMessage
                        .where(mailbox: mailbox, direction: "incoming", application_id: nil)
                        .includes(:candidate, :application)
                        .order(received_at: :desc, created_at: :desc)
                        .limit(200)

    @thread_groups = @email_messages.group_by(&:thread_id)

    @selected_thread_id = params[:thread_id]

    @selected_messages =
      if @selected_thread_id.present?
        EmailMessage
          .where(
            mailbox: mailbox,
            thread_id: @selected_thread_id
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

    @pending_email_count = @email_messages
                            .where(
                              direction: "incoming",
                              status: "received"
                            )
                            .count

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
end