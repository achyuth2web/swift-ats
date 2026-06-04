class InterviewGenController < ApplicationController
  QUESTIONS = {
  # Languages
  "Ruby" => [
    "Explain blocks, procs, and lambdas",
    "What are Ruby modules and mixins?",
    "How does Ruby memory management work?",
    "Explain metaprogramming in Ruby"
  ],

  "Python" => [
    "Explain Python decorators",
    "What are generators?",
    "How does the GIL work?",
    "List vs Tuple differences"
  ],

  "Java" => [
    "Explain JVM architecture",
    "What are the OOP principles?",
    "How does garbage collection work?",
    "Explain Java Collections Framework"
  ],

  # Frontend
  "React" => [
    "Explain Virtual DOM",
    "How do hooks work?",
    "What is Context API?",
    "How do you optimize React applications?"
  ],

  "Angular" => [
    "Explain Angular lifecycle hooks",
    "What is dependency injection?",
    "What are Angular modules?",
    "How does change detection work?"
  ],

  "Vue" => [
    "Explain Vue reactivity",
    "Vue Composition API vs Options API",
    "What are Vue directives?",
    "How do Vue components communicate?"
  ],

  # Backend
  "Ruby on Rails" => [
    "Explain MVC architecture",
    "What are ActiveRecord associations?",
    "How does Rails routing work?",
    "Explain background jobs in Rails"
  ],

  "Node.js" => [
    "Explain Event Loop",
    "How does Express middleware work?",
    "What are streams?",
    "How do you handle async operations?"
  ],

  "Spring Boot" => [
    "Explain dependency injection",
    "What is Spring Boot auto-configuration?",
    "How do REST controllers work?",
    "How do you secure a Spring Boot API?"
  ],

  # Databases
  "SQL" => [
    "Explain different JOIN types",
    "How do indexes work?",
    "Explain normalization",
    "What are ACID properties?"
  ],

  "PostgreSQL" => [
    "Explain indexing strategies",
    "What are materialized views?",
    "How does MVCC work?",
    "Partitioning vs sharding?"
  ],

  "MongoDB" => [
    "Explain document databases",
    "Embedded vs referenced documents",
    "What are aggregation pipelines?",
    "How does indexing work in MongoDB?"
  ],

  # Cloud
  "AWS" => [
    "Explain IAM",
    "EC2 vs Lambda",
    "What is a VPC?",
    "How do you secure cloud resources?"
  ],

  "Azure" => [
    "Explain Azure Resource Groups",
    "What are Azure Functions?",
    "How does Azure AD work?",
    "Explain Azure Storage options"
  ],

  "GCP" => [
    "What is Google Cloud IAM?",
    "Cloud Run vs GKE",
    "BigQuery use cases",
    "How does GCP networking work?"
  ],

  # DevOps
  "Docker" => [
    "What is containerization?",
    "Explain Docker layers",
    "What is Docker Compose?",
    "How are volumes used?"
  ],

  "Kubernetes" => [
    "What is a Pod?",
    "Deployment vs StatefulSet",
    "Explain Services and Ingress",
    "How do namespaces work?"
  ],

  "Terraform" => [
    "What is Infrastructure as Code?",
    "Explain Terraform state",
    "Modules vs Workspaces",
    "How do you manage secrets?"
  ],

  # AI / ML
  "Machine Learning" => [
    "Supervised vs Unsupervised learning",
    "What is overfitting?",
    "Explain cross-validation",
    "How do you evaluate models?"
  ],

  "TensorFlow" => [
    "Explain TensorFlow architecture",
    "What are tensors?",
    "How do neural networks train?",
    "How do you prevent overfitting?"
  ],

  "LangChain" => [
    "What are chains?",
    "Explain retrieval augmented generation",
    "How do agents work?",
    "How do you manage prompt templates?"
  ],

  # BI
  "Power BI" => [
    "Explain DAX",
    "What are relationships?",
    "Import vs DirectQuery",
    "How do you optimize dashboards?"
  ],

  "Tableau" => [
    "How do Tableau extracts work?",
    "Explain calculated fields",
    "What are parameters?",
    "How do you optimize dashboards?"
  ],

  # Testing
  "RSpec" => [
    "Describe RSpec structure",
    "What are shared examples?",
    "Mocking vs stubbing?",
    "How do you test Rails controllers?"
  ],

  "Selenium" => [
    "Explain Selenium WebDriver",
    "How do you handle waits?",
    "Page Object Model?",
    "How do you automate cross-browser testing?"
  ],

  # Project Management
  "Agile" => [
    "What are Agile principles?",
    "Scrum vs Kanban?",
    "What is sprint planning?",
    "How do you estimate stories?"
  ],

  "Jira" => [
    "How do you manage workflows?",
    "Explain boards and backlogs",
    "How do you track sprint progress?",
    "What reports do you use?"
  ],

  # CRM
  "Salesforce" => [
    "What are objects in Salesforce?",
    "Explain Apex",
    "What are workflows?",
    "How do integrations work?"
  ],

  # HR
  "HRBP" => [
    "How do you resolve employee conflicts?",
    "Describe workforce planning",
    "How do you partner with leaders?",
    "Which HR metrics do you track?"
  ],

  # Marketing
  "SEO" => [
    "What affects search rankings?",
    "On-page vs Off-page SEO?",
    "How do backlinks work?",
    "How do you measure SEO success?"
  ],

  # Default
  "default" => [
    "Tell me about yourself",
    "What are your key strengths?",
    "Describe your most challenging project",
    "Where do you see yourself in 5 years?",
    "Why are you looking for a change?",
    "How do you handle tight deadlines?",
    "What questions do you have for us?"
  ]
}
  def index
    @candidates = current_user.visible_candidates.order(:name)
    @jobs       = current_user.visible_jobs.order(:title)
  end
  def generate
    skills = params[:skills].to_s.split(",").map(&:strip)
    role   = params[:role].to_s
    level  = params[:level].to_s
    questions = []
    skills.each { |s| questions.concat((QUESTIONS[s] || [])) }
    questions.concat(QUESTIONS["default"])
    render json: { questions: questions.uniq.first(12), role: role, level: level }
  end
end
