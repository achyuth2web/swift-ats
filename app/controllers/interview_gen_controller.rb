class InterviewGenController < ApplicationController
  QUESTIONS = {
    "React"      => ["Explain the virtual DOM and reconciliation","How do React hooks work? Explain useState and useEffect","What is the Context API and when to use it?","Describe React performance optimization techniques"],
    "Python"     => ["Explain Python decorators with an example","What are generators and when to use them?","How does the GIL affect threading?","List comprehensions vs map/filter"],
    "Java"       => ["Explain JVM architecture","What are the four OOP principles?","How does garbage collection work?","Describe the Java Collections Framework"],
    "Node.js"    => ["What is the Node.js event loop?","Explain Express.js middleware","How to handle async operations?","Describe Node.js streams"],
    "AWS"        => ["Compare EC2, Lambda, and ECS","Explain S3 storage classes","What is a VPC and how do you secure it?","How does IAM work?"],
    "Docker"     => ["What is containerization?","Explain Dockerfile best practices","What is Docker Compose?","Describe Docker volume management"],
    "Kubernetes" => ["What is a Pod?","Explain Kubernetes services and ingress","Deployment vs StatefulSet?","Describe namespace use cases"],
    "SQL"        => ["Explain all types of JOINs","How do indexes improve performance?","Describe normalization forms","What is ACID?"],
    "TypeScript" => ["Key differences from JavaScript?","Explain generics","Interfaces vs types?","Describe utility types"],
    "HRBP"       => ["How do you handle employee conflict?","Describe your talent acquisition approach","How do you partner with business leaders?","What HR metrics do you track?"],
    "default"    => ["Tell me about yourself","What are your key strengths?","Describe your most challenging project","Where do you see yourself in 5 years?","Why are you looking for a change?","How do you handle tight deadlines?","What questions do you have for us?"]
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
    skills.each { |s| questions.concat((QUESTIONS[s] || []).first(3)) }
    questions.concat(QUESTIONS["default"])
    render json: { questions: questions.uniq.first(12), role: role, level: level }
  end
end
