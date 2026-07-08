class UploadController < ApplicationController
  def index; end
  def parse
    file = params[:resume]
    return render(json: { error: "No file" }, status: :bad_request) unless file
    max_size = 5.megabytes
    # max_size = 200.kilobytes # for testing
    allowed_types = [
      "application/pdf",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/msword",
      'text/plain'
    ]

    unless allowed_types.include?(file.content_type)
      return render(
        json: { error: "Only PDF, Word and Text documents are allowed" },
        status: :unprocessable_content
      )
    end

    Rails.logger.info "Uploaded file: #{file.original_filename}, size: #{file.size} bytes, content type: #{file.content_type}"
    if file.size > max_size
      return render(
        json: { error: "File size cannot exceed 5 MB" },
        status: :unprocessable_content
      )
    end
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
  def extract_phone(text)
    candidates = text.scan(/(?:\+?\d{1,3}[-.\s]?)?\(?\d[\d\-.\s()]{7,15}\d/)

    candidates.each do |candidate|
      digits = candidate.gsub(/\D/, "")
      next if digits.length < 10

      digits = digits[-10..-1] if digits.length > 10
      return digits if digits.match?(/\A[6-9]\d{9}\z/)
    end

    ""
  end

  # Matches any short header line ending in "skills"/"competency(-ies)"/"expertise", optionally
  # preceded by qualifiers ("Core Skills", "Key Skills", "Areas of Expertise", "Core Competencies"...)
  # instead of enumerating every phrasing a resume author might use.
  SKILL_HEADER_CORE = "skills?|competenc(?:y|ies)|expertise|skill\\s*set"
  SKILL_SECTION_HEADER = /\A[a-z&\/\s]{0,30}\b(?:#{SKILL_HEADER_CORE})\b\s*:?\z/i
  SKILL_SECTION_HEADER_INLINE = /\A[a-z&\/\s]{0,30}\b(?:#{SKILL_HEADER_CORE})\b\s*[:\-]\s*(.+)\z/i
  SKILL_SECTION_STOP = /\A(experience|work\s+experience|employment\s+history|professional\s+experience|education|projects?|certifications?|summary|objective|profile|achievements|awards|publications|references|languages|interests|hobbies|training)\s*:?\z/i

  # Resume authors phrase skills in endless ways ("Full-Cycle Recruiting", "Boolean Search", etc.)
  # that a fixed skill_lib can never fully enumerate, so pull the candidate's own Skills
  # section verbatim as a fallback alongside the curated library matches. The header and its
  # content may be on the same line ("Skills: A, B, C") or the content may follow on subsequent
  # lines, so both shapes are handled.
  def extract_skill_section(text)
    lines = text.split("\n")
    start_idx = lines.find_index do |l|
      stripped = l.strip
      stripped.match?(SKILL_SECTION_HEADER) || stripped.match?(SKILL_SECTION_HEADER_INLINE)
    end
    return "" unless start_idx

    collected = []
    inline_match = lines[start_idx].strip.match(SKILL_SECTION_HEADER_INLINE)
    collected << inline_match[1] if inline_match

    (start_idx + 1...lines.length).each do |i|
      stripped = lines[i].strip
      break if stripped.match?(SKILL_SECTION_STOP)
      break if stripped.empty? && collected.any?
      break if collected.length >= 20

      collected << lines[i] unless stripped.empty?
    end
    collected.join("\n")
  end

  def split_skill_terms(section_text)
    return [] if section_text.empty?

    section_text
      .split(/[•·▪●|,;()\n]/)
      .map { |s| s.strip.gsub(/\A[-:]+\s*|\s*[-:]+\z/, "") }
      .reject { |s| s.empty? || s.length > 40 || s.split.length > 6 }
      .uniq(&:downcase)
  end

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
    phone = extract_phone(text)
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
      "React", "Angular", "Vue", "Next.js", "Nuxt.js", "Svelte", "Ember.js",
      "Redux", "Zustand", "jQuery", "HTML", "CSS", "SCSS", "Sass", "Bootstrap",
      "Tailwind CSS", "Material UI", "Chakra UI", "Ant Design", "Storybook",
      "PWA", "Responsive Web Design", "Webpack", "Vite",

      # Backend
      "Ruby on Rails", "Rails", "Django", "Flask", "FastAPI", "Spring",
      "Spring Boot", "Hibernate", "Micronaut", "Symfony", "Express", "NestJS",
      "Node.js", "ASP.NET", ".NET", ".NET Core", "Laravel", "CodeIgniter",
      "Phoenix", "GraphQL", "REST", "REST API", "SOAP", "gRPC", "WebSocket",

      # Mobile
      "Android", "iOS", "React Native", "Flutter", "Xamarin", "Ionic",
      "Objective-C", "SwiftUI", "Jetpack Compose", "Cordova", "Unity",

      # Databases
      "SQL", "PostgreSQL", "MySQL", "MariaDB", "SQLite", "Oracle", "SQL Server",
      "MongoDB", "Cassandra", "DynamoDB", "Redis", "Elasticsearch",
      "OpenSearch", "Neo4j", "CouchDB", "Couchbase", "Firestore", "BigQuery",
      "Snowflake", "Redshift", "IBM Db2", "Teradata", "InfluxDB",

      # Cloud Platforms
      "AWS", "Azure", "GCP", "IBM Cloud", "Oracle Cloud", "DigitalOcean",
      "Heroku", "Render", "Vercel", "Netlify", "Firebase", "Cloudflare",

      # AWS Services
      "EC2", "S3", "RDS", "Lambda", "ECS", "EKS", "Fargate", "VPC",
      "CloudFront", "Elastic Beanstalk", "Step Functions", "Athena", "Glue",
      "Kinesis", "CloudFormation", "CloudWatch", "IAM", "SNS", "SQS", "SES",
      "Route 53", "API Gateway", "Secrets Manager",

      # DevOps
      "Docker", "Kubernetes", "Terraform", "Ansible", "Chef", "Puppet",
      "Vagrant", "Jenkins", "Bamboo", "TeamCity", "GitHub Actions",
      "GitLab CI", "CircleCI", "ArgoCD", "Helm", "Istio", "Nginx", "Apache",
      "HAProxy", "Linux", "Ubuntu", "CentOS", "Microservices", "CI/CD",
      "HashiCorp Vault", "RabbitMQ", "ActiveMQ", "Celery", "Sidekiq",
      "Grafana", "Prometheus", "Datadog", "New Relic", "Splunk",
      "Kibana", "Logstash",

      # Data Engineering
      "Apache Airflow", "Apache Spark", "Apache Beam", "Apache NiFi",
      "Hadoop", "Kafka", "Databricks", "dbt", "ETL", "ELT", "Hive", "Pig",
      "Presto", "Trino", "Talend", "Informatica", "SSIS",

      # AI / ML
      "TensorFlow", "PyTorch", "Keras", "Scikit-learn", "XGBoost",
      "LightGBM", "Pandas", "Polars", "NumPy", "OpenCV", "NLP",
      "LangChain", "LlamaIndex", "Hugging Face", "MLflow",
      "Deep Learning", "Machine Learning", "Artificial Intelligence",
      "Reinforcement Learning", "Transformers", "BERT", "GPT",
      "Prompt Engineering", "RAG", "Vector Database", "Pinecone",
      "Generative AI", "LLM", "OpenAI", "Computer Vision",

      # BI & Analytics
      "Tableau", "Power BI", "Looker", "Qlik Sense", "Metabase", "SSRS",
      "SSAS", "Domo", "Sisense", "Google Analytics", "Mixpanel", "Amplitude",

      # Testing
      "RSpec", "Minitest", "JUnit", "TestNG", "Mockito", "Selenium",
      "Appium", "Cypress", "Playwright", "Cucumber", "Jest", "Vitest",
      "PyTest", "TDD", "BDD", "Unit Testing", "Manual Testing",
      "Automation Testing", "Functional Testing", "Regression Testing",
      "Sanity Testing", "Smoke Testing", "Integration Testing",
      "System Testing", "UAT", "User Acceptance Testing",
      "Black Box Testing", "White Box Testing", "API Testing",
      "Load Testing", "Performance Testing", "Test Case Design",
      "Test Planning", "Defect Tracking", "SDLC", "STLC",
      "TestRail", "Bugzilla", "Mantis", "Zoho BugTracker", "qTest",
      "LoadRunner", "JMeter", "Postman", "SoapUI",

      # Version Control
      "Git", "GitHub", "GitLab", "Bitbucket", "SVN",

      # Security
      "OAuth", "OAuth 2.0", "JWT", "SAML", "OpenID Connect",
      "PCI DSS", "GDPR", "OWASP", "Cybersecurity", "SSO", "MFA",
      "Zero Trust", "SOC 2", "ISO 27001", "SIEM", "Vulnerability Assessment",
      "Penetration Testing",

      # Project Management
      "Agile", "Scrum", "Kanban", "Waterfall", "V-Model", "PRINCE2", "PMP",
      "SAFe", "Lean", "Six Sigma", "Jira", "Confluence",
      "Trello", "Asana", "ClickUp", "Notion",

      # CRM / ERP
      "Salesforce", "HubSpot", "Zoho CRM", "Zoho Books", "Zoho Desk",
      "NetSuite", "Freshdesk", "Zendesk", "ServiceNow", "SAP",
      "Oracle ERP", "Microsoft Dynamics",

      # Sales
      "Lead Generation", "Cold Calling", "Business Development",
      "Account Management", "Client Relationship Management",
      "Sales Pipeline Management", "Negotiation", "Upselling",
      "Cross-selling", "Quota Attainment", "B2B Sales", "B2C Sales",
      "Inside Sales", "Field Sales", "Sales Forecasting",
      "CRM Management", "Contract Negotiation",

      # Design
      "Figma", "Adobe XD", "Sketch", "Photoshop", "InVision", "Zeplin",
      "Wireframing", "Prototyping", "UI/UX", "User Research",
      "Illustrator", "InDesign", "Canva",

      # Office & Productivity
      "Excel", "Microsoft Excel", "PowerPoint", "Word", "Outlook", "OneNote",
      "VBA", "Google Sheets", "Google Docs", "Google Slides",

      # Networking
      "TCP/IP", "DNS", "DHCP", "VPN", "Firewall", "LAN", "WAN",
      "Subnetting", "Routing", "Switching", "CCNA",
      "Load Balancing", "Reverse Proxy",

      # Healthcare
      "HL7", "FHIR", "HIPAA", "EHR", "EMR", "ICD-10", "CPT",
      "Azalea Health", "Epic", "Cerner", "Meditech", "Athenahealth",
      "Allscripts",

      # HR
      "HRBP", "HRSS", "HR Shared Services", "Talent Acquisition", "Recruiting",
      "Full-Cycle Recruiting", "Full Cycle Recruiting", "Sourcing Strategy",
      "Sourcing", "Boolean Search", "Employer Branding", "Interview Design",
      "Offer Negotiation", "Recruiting Analytics", "Candidate Experience",
      "Onboarding", "Exit Management", "Offboarding", "Attendance Management",
      "Payroll", "Performance Management", "HR Operations",
      "Query Handling", "HR Helpdesk", "Employee Relations", "ATS", "Workday",
      "BambooHR", "Greenhouse", "Lever", "Compensation and Benefits",
      "HRIS", "Statutory Compliance", "Induction", "Grievance Handling",

      # Finance
      "QuickBooks", "Tally", "SAP Finance",
      "Oracle Finance", "Financial Analysis", "Financial Reporting",
      "Accounting", "Bookkeeping", "GAAP", "IFRS", "GAAP/IFRS",
      "Budgeting", "Forecasting", "Auditing", "Taxation",
      "Account Reconciliation", "Month-End Close", "Accounts Payable",
      "Accounts Receivable", "Accounts Payable/Receivable",
      "Variance Analysis", "Internal Controls", "Advanced Excel",
      "VLOOKUP", "Pivot Tables",

      # Marketing
      "SEO", "SEM", "Google Ads", "Facebook Ads",
      "Content Marketing", "Email Marketing", "Social Media Marketing",
      "Affiliate Marketing", "Influencer Marketing", "Brand Management",
      "Copywriting", "A/B Testing", "Mailchimp",

      # Soft Skills
      "Leadership", "Communication", "Teamwork",
      "Problem Solving", "Critical Thinking",
      "Time Management", "Mentoring", "Adaptability",
      "Decision Making", "Conflict Resolution", "Attention to Detail",
      "Multitasking", "Stakeholder Management", "Collaboration"
    ]
    text_downcase = text.downcase
    matched_skills = skill_lib.uniq.select do |skill|
      text.match?(/(?<!\w)#{Regexp.escape(skill)}(?!\w)/i)
    end
    raw_skills = split_skill_terms(extract_skill_section(text))
    all_skills = matched_skills.dup
    seen = all_skills.map(&:downcase).to_set
    raw_skills.each do |term|
      next if seen.include?(term.downcase)
      all_skills << term
      seen << term.downcase
    end
    skills = all_skills
    .sort_by { |skill| text_downcase.index(skill.downcase) || Float::INFINITY }
    dept_kw = {"Tech"=>%w[developer engineer devops scientist software python java react node],
               "HR"=>%w[hr talent recruitment hrbp],
               "Sales"=>["sales", "business development", "account executive", "lead generation"],
               "Finance"=>%w[finance accounting],"Marketing"=>%w[marketing seo]}
    dept_scores = dept_kw.transform_values { |kws| kws.count { |k| text_downcase.include?(k) } }
    dept = dept_scores.values.max.to_i.zero? ? "" : dept_scores.max_by { |_, score| score }.first
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
