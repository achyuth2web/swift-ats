templates = [
  {
    name: "Interview Invitation",
    subject: "Interview Invitation — {role} at {company}",
    body: <<~BODY
      Dear {name},

      Thank you for applying for the {role} position at {company}.
      
      We are pleased to invite you for an interview on {date} at {time}.

      Details:
      - Role: {role}
      - Interviewer: {interviewer}
      - Mode: {mode}
      - Location/Link: {location}

      Please confirm your availability by replying to this email.

      Best regards,
      {recruiter}
      {company}
    BODY
  },
  {
    name: "Offer Letter",
    subject: "Offer Letter — {role} at {company}",
    body: <<~BODY
      Dear {name},

      We are delighted to offer you the position of {role} at {company}.

      Offer Details:
      - Role: {role}
      - CTC: {ctc} LPA
      - Joining Date: {date}
      - Location: {location}

      Kindly sign and return this offer within 3 working days to confirm your acceptance.

      Welcome to the team!

      Warm regards,
      {recruiter}
      {company}
    BODY
  },
  {
    name: "Rejection (Polite)",
    subject: "Update on your application — {role}",
    body: <<~BODY
      Dear {name},

      Thank you for your time and interest in the {role} position at {company}.

      After careful consideration, we have decided to move forward with other candidates whose experience more closely matches our current requirements.

      We truly appreciate the effort you put into the process and encourage you to apply for future openings that align with your profile.
      
      Wishing you all the best.

      Sincerely,
      {recruiter}
      {company}
    BODY
  },
  {
    name: "Shortlist Notification",
    subject: "Good news — you have been shortlisted for {role}",
    body: <<~BODY
      Dear {name},

      We are pleased to inform you that you have been shortlisted for the {role} position at {company}.

      Next steps will be communicated to you shortly. In the meantime, feel free to reach out if you have any questions.

      Best regards,
      {recruiter}
      {company}
    BODY
  },
  {
    name: "Follow-up / Status Check",
    subject: "Following up — {role} application",
    body: <<~BODY
      Dear {name},

      I hope you are doing well. I wanted to follow up regarding your application for the {role} position at {company}.

      We are currently in the evaluation phase and expect to get back to you by {date}.

      Thank you for your patience.

      Best regards,
      {recruiter}
      {company}
    BODY
  }
]

templates.each do |attributes|
  template = EmailTemplate.find_or_initialize_by(name: attributes[:name])
  template.assign_attributes(attributes)
  template.save!
  puts "Loaded template: #{template.name}"
end

puts "Email templates loaded successfully."
