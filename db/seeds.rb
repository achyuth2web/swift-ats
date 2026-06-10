puts "Seeding Spritle ATS..."

admin = User.find_or_create_by!(email: "admin@spritle.com") do |u|
  u.name = "Admin User"; u.password = "admin123"; u.role = "admin"; u.active = true
end

recruiter = User.find_or_create_by!(email: "recruiter@spritle.com") do |u|
  u.name = "Priya Recruiter"; u.password = "recruiter123"; u.role = "recruiter"; u.active = true
end

j1 = Job.find_or_create_by!(title: "Senior React Developer") do |j|
  j.company = "Spritle Software"; j.department = "Tech"; j.hiring_manager = "Rajan Kumar"
  j.position_type = "New"; j.openings = 2; j.status = "Open"
  j.open_date = 25.days.ago.to_date; j.description = "Looking for an experienced React developer."
  j.skills_list = "React,TypeScript,Node.js"; j.experience_years = 4; j.ctc_budget = "28"
end
j1.recruiters << recruiter unless j1.recruiters.include?(recruiter)

j2 = Job.find_or_create_by!(title: "HR Business Partner") do |j|
  j.company = "Spritle Software"; j.department = "HR"; j.hiring_manager = "Sunita Das"
  j.position_type = "Replacement"; j.replacing_employee = "Meera Krishnan"
  j.openings = 1; j.status = "Open"; j.open_date = 15.days.ago.to_date
  j.description = "HRBP role to support the growing team."
  j.skills_list = "HRBP,Talent Acquisition"; j.experience_years = 5; j.ctc_budget = "20"
end
j2.recruiters << recruiter unless j2.recruiters.include?(recruiter)

j3 = Job.find_or_create_by!(title: "DevOps Engineer") do |j|
  j.company = "TechCorp Client"; j.department = "Tech"; j.hiring_manager = "Arjun Mehta"
  j.position_type = "New"; j.openings = 1; j.status = "Closed"
  j.open_date = 60.days.ago.to_date; j.close_date = 10.days.ago.to_date; j.hire_date = 10.days.ago.to_date
  j.description = "DevOps role for infrastructure management."
  j.skills_list = "Kubernetes,Docker,Terraform"; j.experience_years = 3; j.ctc_budget = "22"
end

j4 = Job.find_or_create_by!(title: "Product Manager") do |j|
  j.company = "Spritle Software"; j.department = "Tech"; j.hiring_manager = "Kavita Singh"
  j.position_type = "New"; j.openings = 1; j.status = "Reopened"
  j.open_date = 90.days.ago.to_date; j.close_date = 30.days.ago.to_date; j.reopen_date = 5.days.ago.to_date
  j.description = "Product Manager for our SaaS platform."
  j.skills_list = "Agile,Jira,User Research"; j.experience_years = 5; j.ctc_budget = "35"
end
j4.recruiters << recruiter unless j4.recruiters.include?(recruiter)

[
  { name: "Priya Sharma",  email: "priya@email.com",   phone: "+91 9876543210", role: "Senior React Developer",
    department: "Tech",   skills_list: "React,TypeScript,Node.js,GraphQL,AWS",  experience_years: 5,
    designation: "Frontend Lead", status: "Interview", score: 88, source: "LinkedIn",
    ctc_current: "18", ctc_expected: "24", ctc_unit: "LPA", notice_period: "30",
    notes: "Strong profile", job: j1, recruiter: recruiter },
  { name: "Rahul Verma",   email: "rahul@email.com",   phone: "+91 8765432109", role: "HR Business Partner",
    department: "HR",     skills_list: "HRBP,Talent Acquisition,Performance Management", experience_years: 7,
    designation: "Senior HR Manager", status: "Screening", score: 75, source: "Referral",
    ctc_current: "14", ctc_expected: "18", ctc_unit: "LPA", notice_period: "60",
    job: j2, recruiter: recruiter },
  { name: "Ananya Singh",  email: "ananya@email.com",  phone: "+91 7654321098", role: "Data Analyst",
    department: "Tech",   skills_list: "Python,SQL,Tableau,Power BI", experience_years: 3,
    designation: "Data Analyst", status: "New", score: 82, source: "Job Board",
    ctc_current: "9", ctc_expected: "13", ctc_unit: "LPA", notice_period: "30" },
  { name: "Karan Mehta",   email: "karan@email.com",   phone: "+91 6543210987", role: "Sales Executive",
    department: "Sales",  skills_list: "B2B Sales,CRM,Negotiation", experience_years: 4,
    designation: "Sales Manager", status: "Offer", score: 91, source: "LinkedIn",
    ctc_current: "12", ctc_expected: "16", ctc_unit: "LPA", notice_period: "15",
    notes: "Excellent communication", recruiter: recruiter },
  { name: "Sneha Patel",   email: "sneha@email.com",   phone: "+91 9988776655", role: "Product Manager",
    department: "Tech",   skills_list: "Agile,Jira,User Research", experience_years: 6,
    designation: "Product Manager", status: "Rejected", score: 60, source: "Naukri",
    ctc_current: "22", ctc_expected: "28", ctc_unit: "LPA", notice_period: "90",
    job: j4, recruiter: recruiter },
  { name: "Vikram Das",    email: "vikram@email.com",  phone: "+91 8877665544", role: "DevOps Engineer",
    department: "Tech",   skills_list: "Kubernetes,Docker,CI/CD,Terraform", experience_years: 4,
    designation: "DevOps Engineer", status: "New", score: 79, source: "Naukri",
    ctc_current: "16", ctc_expected: "21", ctc_unit: "LPA", notice_period: "30",
    job: j1, recruiter: recruiter }
].each do |attrs|
  job_ref = attrs.delete(:job)
  rec_ref = attrs.delete(:recruiter)
  Candidate.find_or_create_by!(email: attrs[:email]) do |c|
    c.assign_attributes(attrs)
    c.job = job_ref
    c.recruiter = rec_ref
  end
end

ActivityLog.create!(message: "Spritle ATS initialized", user: admin) if ActivityLog.count == 0
puts "Done! admin@spritle.com / admin123  |  recruiter@spritle.com / recruiter123"
