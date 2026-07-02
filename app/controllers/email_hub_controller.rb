# app/controllers/email_hubs_controller.rb

class EmailHubController < ApplicationController
  before_action :authenticate_user!

  def index
    @email_templates = email_templates
    @candidates = current_user.visible_candidates
                              .includes(:job)
                              .order(:name)
    @email_logs = EmailLog.where(user: current_user)
                          .order(created_at: :desc)
                          .limit(100)
  end

  def send_email
    candidate = Candidate.find_by(id: params[:candidate_id])

    EmailLog.create!(
      user: current_user,
      candidate: candidate,
      template_name: params[:template_name],
      subject: params[:subject],
      recipient_email: params[:to]
    )

    # Send later with Sidekiq
    # EmailHubMailer.custom_email(...).deliver_later

    redirect_to email_hub_path,
                notice: "Email queued successfully."
  end

  def clear_log
    EmailLog.where(user: current_user).delete_all

    redirect_to email_hub_path,
                notice: "Email log cleared."
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
end