class InterviewMailer < ApplicationMailer
  def feedback_request(interview)
    @interview = interview
    @feedback_url = interview_feedback_url(token: interview.feedback_token)
    mail(to: interview.interviewer_email,
         subject: "Interview Feedback Requested — #{interview.candidate.name}")
  end
end
