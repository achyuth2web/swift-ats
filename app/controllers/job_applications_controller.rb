class JobApplicationsController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.recruiter?
      load_assigned
      return
    end

    case params[:tab]
    when "assigned"
      load_assigned
    else
      load_unassigned
    end
  end

  def show
    mailbox = ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com")

    @email_message = EmailMessage
      .includes(:candidate, :assigned_to)
      .find_by!(
        id: params[:id],
        mailbox: mailbox,
        direction: "incoming"
      )

    @recruiters = User.kept.where(role: "recruiter", active: true).where.not(id: current_user.id).order(:name)
    @email_templates = email_templates
    @email_message_attachments = []

    integration = GmailIntegration.recruitment.first

    if integration && @email_message.message_id.present?
      begin
        gmail = GmailService.new(integration)

        @email_message_attachments =
          gmail.list_attachments(@email_message.message_id)
      rescue Google::Apis::ClientError => e
        Rails.logger.error(
          "Gmail attachment retrieval failed for message " \
          "#{@email_message.message_id}: #{e.message}"
        )
      end
    end

    @activities = @email_message.job_application_activities
                            .includes(:actor, :from_user, :to_user)
                            .order(created_at: :desc)
  end

  def assign
    unless current_user.admin?
      return redirect_to job_applications_path,
                        alert: "You are not authorized to assign applications."
    end

    @email_message = EmailMessage.find(params[:message_id])

    recruiter = User.find(params[:assigned_to_id])

    unless recruiter.recruiter?
      return redirect_to job_application_message_path(@email_message),
                        alert: "Please select a valid recruiter."
    end

    previous_recruiter = @email_message.assigned_to

    EmailMessage.transaction do
      @email_message.update!(assigned_to: recruiter)

      JobApplicationActivity.create!(
        email_message: @email_message,
        actor: current_user,
        from_user: previous_recruiter,
        to_user: recruiter,
        action: previous_recruiter.present? ? "reassigned" : "assigned",
        details: { message: "Assigned to #{recruiter.name}" }
      )
    end

    redirect_to job_applications_path(tab: "assigned"),
                notice: "Application assigned to #{recruiter.name}."
  end

  def process_application
    @email_message = EmailMessage.find(params[:message_id])

    unless current_user.recruiter? &&
          @email_message.assigned_to_id == current_user.id
      return redirect_to job_applications_path(tab: "assigned"),
                        alert: "Not authorized."
    end

    case params[:decision]
    when "shortlist"
      add_to_ats
    when "forward"
      forward_application
    when "maybe"
      mark_under_review
    when "reject"
      reject_application
    else
      redirect_to job_application_message_path(@email_message),
                  alert: "Invalid decision."
    end
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

  def load_unassigned
    mailbox = ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com")

    messages = EmailMessage
      .where(
        mailbox: mailbox,
        direction: "incoming",
        status: "received",
        application_id: nil,
        assigned_to_id: nil
      )
      .order(received_at: :desc, created_at: :desc)

    @pending_email_count = messages.count

    @email_messages = messages
      .page(params[:page])
      .per(10)

    @selected_message = @email_messages.find_by(id: params[:message_id]) if params[:message_id].present?
  end

  def load_assigned
    mailbox = ENV.fetch("RECRUITMENT_MAILBOX", "jobs@spritle.com")

    messages = EmailMessage
      .where(
        mailbox: mailbox,
        status: "received",
        direction: "incoming"
      )
      .where.not(assigned_to_id: nil)
      .includes(:candidate, :assigned_to)
      .order(updated_at: :desc)

    messages = messages.where(assigned_to_id: current_user.id) if current_user.recruiter?

    @assigned_email_count = messages.count

    @email_messages = messages
      .page(params[:page])
      .per(10)

    @selected_message = @email_messages.find_by(id: params[:message_id]) if params[:message_id].present?
  end

  def add_to_ats
    applicant_email = extract_applicant_email(@email_message.from_email)

    if applicant_email.blank?
      return redirect_to job_applications_path(tab: "assigned"),
                        alert: "Unable to identify the applicant's email address."
    end

    normalized_email = applicant_email.downcase

    matched_jobs = EmailJobMatcher.new(@email_message).matched_jobs

    job = matched_jobs.find do |matched_job|
      matched_job.recruiters.exists?(id: current_user.id)
    end

    unless job
      return redirect_to job_applications_path(tab: "assigned"),
                        alert: "No matching job opening was found for this recruiter."
    end

    EmailMessage.transaction do
      @email_message.lock!

      if @email_message.application_id.present? ||
        @email_message.application_status == "rejected"
        raise ActiveRecord::RecordNotFound
      end

      # Find existing candidate using case-insensitive email.
      candidate = Candidate.where(
        "LOWER(email) = ?",
        normalized_email
      ).first

      # Prevent using a candidate owned by another recruiter.
      if candidate.present? &&
        candidate.recruiter_id.present? &&
        candidate.recruiter_id != current_user.id
        raise CandidateOwnedByAnotherRecruiter
      end

      unless candidate
        candidate = Candidate.create!(
          email: normalized_email,
          name: normalized_email.split("@").first,
          recruiter_id: current_user.id,
          job_id: job.id,
          status: "New"
        )
      end

      candidate.update!(recruiter_id: current_user.id) if candidate.recruiter_id.blank?

      # Create ATS application.
      application = Application.create!(
        candidate: candidate,
        job: job,
        status: "open",
        assigned_to_id: current_user.id,
        source: "email",
        source_email: normalized_email,
        applied_at: Time.current
      )

      # Update original email message.
      @email_message.update!(
        application_id: application.id,
        application_status: "shortlisted"
      )

      # Track shortlist activity.
      JobApplicationActivity.create!(
        email_message: @email_message,
        actor: current_user,
        action: "shortlisted",
        details: {
          candidate_id: candidate.id,
          candidate_name: candidate.name,
          candidate_email: candidate.email,
          job_id: job.id,
          job_title: job.title
        }
      )
    end

    redirect_to job_applications_path(tab: "assigned"),
                notice: "Candidate successfully shortlisted and added to ATS pipeline."

  rescue ActiveRecord::RecordNotFound
    redirect_to job_applications_path(tab: "assigned"),
                alert: "Application not found or already processed."

  rescue ActiveRecord::RecordInvalid => e
    redirect_to job_applications_path(tab: "assigned"),
                alert: "Unable to shortlist candidate: #{e.record.errors.full_messages.join(', ')}"

  rescue => e
    Rails.logger.error(e.full_message)
    Rails.logger.error(
      "Shortlisting failed: #{e.class}: #{e.message}"
    )

    redirect_to job_applications_path(tab: "assigned"),
                alert: "Unable to shortlist candidate. Please try again."
  end

  def forward_application
    recruiter = User.find_by(
      id: params[:recruiter_id],
      role: "recruiter"
    )

    return redirect_back(
      fallback_location: job_application_message_path(@email_message),
      alert: "Select a valid recruiter."
    ) unless recruiter

    previous_recruiter = @email_message.assigned_to

    EmailMessage.transaction do
      @email_message.update!(
        assigned_to: recruiter,
        application_status: "forwarded"
      )

      JobApplicationActivity.create!(
        email_message: @email_message,
        actor: current_user,
        from_user: previous_recruiter,
        to_user: recruiter,
        action: "forwarded",
        details: {
          recipient: recruiter.email,
          subject: params[:email_subject]
        }
      )
    end

    redirect_to job_applications_path(tab: "assigned"),
                notice: "Application forwarded successfully."
  end

  def mark_under_review
    recruiter = User.find_by(
      id: params[:recruiter_id],
      role: "recruiter"
    )

    return redirect_back(
      fallback_location: job_application_message_path(@email_message),
      alert: "Please select a valid recruiter."
    ) unless recruiter && recruiter.id != current_user.id

    integration = GmailIntegration.recruitment.first

    unless integration
      return redirect_back(
        fallback_location: job_application_message_path(@email_message),
        alert: "Gmail integration is not configured."
      )
    end

    # Send email to selected recruiter
    result = GmailService.new(integration).send_new_email(
      to: recruiter.email,
      cc: params[:cc_emails],
      subject: params[:subject],
      body: params[:body]
    )

    previous_recruiter = @email_message.assigned_to

    EmailMessage.transaction do
      @email_message.update!(
        assigned_to: recruiter,
        application_status: "under_review"
      )

      JobApplicationActivity.create!(
        email_message: @email_message,
        actor: current_user,
        from_user: previous_recruiter,
        to_user: recruiter,
        action: "marked_maybe",
        details: {
          forwarded_to: recruiter.email,
          subject: params[:subject],
          cc: params[:cc_emails],
          feedback_required: true,
          gmail_message_id: result["id"],
          gmail_thread_id: result["threadId"]
        }
      )
    end

    redirect_to job_applications_path(tab: "assigned"),
                notice: "Application forwarded for further review."

  rescue => e
    Rails.logger.error(
      "Mark under review failed: #{e.class}: #{e.message}"
    )
    Rails.logger.error(e.backtrace.join("\n"))

    redirect_back(
      fallback_location: job_application_message_path(@email_message),
      alert: "Could not forward application. Please try again."
    )
  end

  def reject_application
    email_message = EmailMessage.find(params[:message_id])

    integration = GmailIntegration.recruitment.first

    result = GmailService.new(integration).send_new_email(
      to: email_message.from_email,
      cc: params[:cc],
      subject: params[:subject],
      body: params[:body]
    )

    email_message.update!(application_status: "rejected")

    JobApplicationActivity.create!(
      email_message: email_message,
      actor: current_user,
      action: "rejected",
      details: {
        subject: params[:subject],
        recipient: email_message.from_email
      }
    )

    redirect_to job_applications_path(tab: "assigned"),
                notice: "Rejection email sent successfully."
  rescue => e
    Rails.logger.error(
      "Application rejection failed: #{e.class}: #{e.message}"
    )

    redirect_to job_applications_path(tab: "assigned"),
                alert: "Could not send rejection email. Please try again."
  end

  def extract_applicant_email(from_email)
    from_email.to_s[/[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}/i]
  end
end