class UploadController < ApplicationController
  def index; end
  def parse
    file = params[:resume]
    return render(json: { error: "No file" }, status: :bad_request) unless file
    text   = extract_text(file)
    parsed = parse_resume(text)
    render json: parsed
  rescue => e
    Rails.logger.error "Error parsing resume: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end
  def create
    attrs = params.require(:candidate).permit(
      :name,:email,:phone,:role,:department,:designation,:skills_list,
      :experience_years,:ctc_current,:ctc_expected,:ctc_unit,:notice_period,
      :score,:source,:job_id,:resume_text,:resume_filename,:resume)
    candidate = Candidate.new(attrs.except(:resume))
    candidate.recruiter = current_user unless admin?
    candidate.status    = "New"
    if candidate.save
      if params[:candidate][:resume].present?
        Rails.logger.info "Uploading resume for candidate #{candidate.id}: #{params[:candidate][:resume].original_filename}"
        resume = params[:candidate][:resume]
        file_key = "resumes/#{candidate.id}/#{SecureRandom.uuid}_#{resume.original_filename}"

        Uploads::S3Bucket.new.update_file(
          file_key,
          resume.tempfile,
          resume.content_type
        )

        candidate.update_column(:resume_file_key, file_key)
      end
      log_activity("#{current_user.name} uploaded resume: #{candidate.name}")
      render json: { id: candidate.id, name: candidate.name }
    else
      Rails.logger.error(
        "Candidate save failed: #{candidate.errors.full_messages.join(', ')}"
      )
      render json: { errors: candidate.errors.full_messages }, status: :unprocessable_content
    end
  end
  private
  def extract_text(file)
    ext = File.extname(file.original_filename).downcase
    case ext
    when ".pdf"
      reader = PDF::Reader.new(file.tempfile)
      reader.pages.map(&:text).join("\n")
    when ".docx"
      doc = Docx::Document.open(file.tempfile.path)
      doc.paragraphs.map(&:text).join("\n")
    else
      file.read
    end
  rescue
    ""
  end
  def parse_resume(text)
    name  = extract_name(text)
    email = text.scan(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/).first || ""
    phone = text.scan(/(?:\+91[\-\s]?)?[6-9]\d{9}/).first || ""
    exp_m = text.match(/(\d+(?:\.\d+)?)\+?\s*(?:years?|yrs?)\s*(?:of\s+)?(?:experience|exp)/i)
    exp   = exp_m ? exp_m[1].to_f.round : 0
    ctc_m = text.match(/current\s*(?:ctc|salary)[:\s]*(?:rs\.?|inr|₹)?\s*(\d+(?:\.\d+)?)\s*(?:lpa|l)/i) ||
             text.match(/(\d+(?:\.\d+)?)\s*(?:lpa|l\.p\.a)/i)
    ctc_c = ctc_m ? ctc_m[1] : ""
    em    = text.match(/expected\s*(?:ctc|salary)[:\s]*(?:rs\.?|inr|₹)?\s*(\d+(?:\.\d+)?)\s*(?:lpa|l)/i)
    ctc_e = em ? em[1] : ""
    nm    = text.match(/notice\s*period[:\s]*(\d+)\s*(days?|months?)/i)
    notice = if nm
      nm[2].downcase.include?("month") ? (nm[1].to_i * 30).to_s : nm[1]
    elsif text.match?(/immediate|no\s*notice/i) then "0"
    else "" end
    skill_lib = [
      # Programming Languages
      "Ruby", "Python", "Java", "JavaScript", "TypeScript", "C", "C++", "C#",
      "Go", "Rust", "Kotlin", "Scala", "Swift", "PHP", "Perl", "R", "MATLAB",
      "Dart", "Groovy", "Elixir", "Haskell", "Bash", "PowerShell",

      # Frontend
      "React", "Angular", "Vue", "Next.js", "Nuxt.js", "Svelte", "Redux",
      "Zustand", "jQuery", "HTML", "CSS", "SCSS", "Sass", "Bootstrap",
      "Tailwind CSS", "Material UI", "Chakra UI", "Ant Design",
      "Webpack", "Vite",

      # Backend
      "Ruby on Rails", "Rails", "Django", "Flask", "FastAPI", "Spring",
      "Spring Boot", "Hibernate", "Express", "NestJS", "Node.js",
      "ASP.NET", "Laravel", "CodeIgniter", "Phoenix", "GraphQL", "REST", "SOAP",

      # Mobile
      "Android", "iOS", "React Native", "Flutter", "Xamarin", "Ionic",

      # Databases
      "PostgreSQL", "MySQL", "MariaDB", "SQLite", "Oracle", "SQL Server",
      "MongoDB", "Cassandra", "DynamoDB", "Redis", "Elasticsearch",
      "OpenSearch", "Neo4j", "CouchDB", "Firestore", "BigQuery", "Snowflake",

      # Cloud Platforms
      "AWS", "Azure", "GCP", "DigitalOcean", "Heroku", "Render",
      "Vercel", "Netlify", "Firebase", "Cloudflare",

      # AWS Services
      "EC2", "S3", "RDS", "Lambda", "ECS", "EKS", "Fargate",
      "CloudFormation", "CloudWatch", "IAM", "SNS", "SQS", "SES",
      "Route 53", "API Gateway", "Secrets Manager",

      # DevOps
      "Docker", "Kubernetes", "Terraform", "Ansible", "Chef", "Puppet",
      "Jenkins", "GitHub Actions", "GitLab CI", "CircleCI",
      "ArgoCD", "Helm", "Nginx", "Apache", "HAProxy",
      "Linux", "Ubuntu", "CentOS",

      # Data Engineering
      "Apache Airflow", "Apache Spark", "Hadoop", "Kafka", "Databricks",
      "dbt", "ETL", "ELT", "Hive", "Pig", "Presto", "Trino",

      # AI / ML
      "TensorFlow", "PyTorch", "Keras", "Scikit-learn", "XGBoost",
      "LightGBM", "Pandas", "Polars", "NumPy", "OpenCV", "NLP",
      "LangChain", "LlamaIndex", "Hugging Face", "MLflow",
      "Deep Learning", "Machine Learning",

      # BI & Analytics
      "Tableau", "Power BI", "Looker", "Qlik Sense", "Metabase",
      "Google Analytics", "Mixpanel", "Amplitude",

      # Testing
      "RSpec", "Minitest", "JUnit", "Mockito", "Selenium",
      "Cypress", "Playwright", "Cucumber", "Jest", "Vitest",

      # Version Control
      "Git", "GitHub", "GitLab", "Bitbucket", "SVN",

      # Security
      "OAuth", "OAuth 2.0", "JWT", "SAML", "OpenID Connect",
      "PCI DSS", "GDPR", "OWASP", "Cybersecurity",
      "Penetration Testing",

      # Project Management
      "Agile", "Scrum", "Kanban", "Jira", "Confluence",
      "Trello", "Asana", "ClickUp", "Notion",

      # CRM / ERP
      "Salesforce", "HubSpot", "Zoho CRM", "SAP",
      "Oracle ERP", "Microsoft Dynamics",

      # Design
      "Figma", "Adobe XD", "Sketch", "Photoshop",
      "Illustrator", "InDesign", "Canva",

      # Networking
      "TCP/IP", "DNS", "DHCP", "VPN",
      "Load Balancing", "Reverse Proxy",

      # Healthcare
      "HL7", "FHIR", "HIPAA", "EHR", "EMR",
      "Azalea Health", "Epic", "Cerner",

      # HR
      "HRBP", "Talent Acquisition", "Recruiting",
      "Onboarding", "Payroll", "Performance Management",
      "Employee Relations", "ATS", "Workday",
      "BambooHR", "Greenhouse", "Lever",

      # Finance
      "QuickBooks", "Tally", "SAP Finance",
      "Oracle Finance", "Financial Analysis", "Accounting",

      # Marketing
      "SEO", "SEM", "Google Ads", "Facebook Ads",
      "Content Marketing", "Email Marketing",

      # Soft Skills
      "Leadership", "Communication", "Teamwork",
      "Problem Solving", "Critical Thinking",
      "Time Management", "Mentoring",
      "Stakeholder Management", "Collaboration"
    ]
    skills = skill_lib
    .sort_by { |skill| -skill.length }
    .select do |skill|
      text.match?(/(?<!\w)#{Regexp.escape(skill)}(?!\w)/i)
    end
    .uniq
    .first(12)
    dept_kw = {"Tech"=>%w[developer engineer devops scientist software python java react node],
               "HR"=>%w[hr talent recruitment hrbp],"Sales"=>%w[sales business development],
               "Finance"=>%w[finance accounting],"Marketing"=>%w[marketing seo]}
    dept = "Tech"
    dept_kw.each { |d,kws| dept = d and break if kws.any? { |k| text.downcase.include?(k) } }
    { name: name, email: email, phone: phone, experience: exp,
      ctcCurrent: ctc_c, ctcExpected: ctc_e, noticePeriod: notice,
      skills: skills, department: dept }
  end
  TITLE_WORDS = %w[
    Engineer Developer Architect Consultant Analyst
    Manager Lead Director Specialist Designer
    Scientist Recruiter Administrator Programmer
    Vision AI ML Data Software Full Stack Backend Frontend
  ]
  def extract_name(text)
    lines = text.split("\n").map(&:strip).reject(&:empty?)

    lines.first(10).each do |line|
      next if line.match?(/resume|curriculum|vitae|cv|@/i)
      next if line.length > 60

      words = line.split

      Rails.logger.info "Name candidate: #{line}"

      # Skip job titles
      next if words.any? { |w| TITLE_WORDS.include?(w.gsub(/[^\w]/, '')) }

      if line.match?(/\A[A-Z][A-Za-z.\s]+\z/)
        return line
      end
    end

    "Unknown"
  end
end
