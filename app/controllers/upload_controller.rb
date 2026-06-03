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
      :score,:source,:job_id,:resume_text,:resume_filename)
    candidate = Candidate.new(attrs)
    candidate.recruiter = current_user unless admin?
    candidate.status    = "New"
    if candidate.save
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
    skill_lib = %w[React Angular Vue Node.js Python Java TypeScript JavaScript AWS Azure GCP
                   Docker Kubernetes Terraform SQL MySQL PostgreSQL MongoDB Redis GraphQL
                   Agile Scrum Jira Figma HRBP Salesforce SEO Power\ BI Tableau]
    skills = skill_lib.select { |s| text.match?(/\b#{Regexp.escape(s)}\b/i) }.first(12)
    dept_kw = {"Tech"=>%w[developer engineer devops scientist software python java react node],
               "HR"=>%w[hr talent recruitment hrbp],"Sales"=>%w[sales business development],
               "Finance"=>%w[finance accounting],"Marketing"=>%w[marketing seo]}
    dept = "Tech"
    dept_kw.each { |d,kws| dept = d and break if kws.any? { |k| text.downcase.include?(k) } }
    { name: name, email: email, phone: phone, experience: exp,
      ctcCurrent: ctc_c, ctcExpected: ctc_e, noticePeriod: notice,
      skills: skills, department: dept }
  end
  def extract_name(text)
    lines = text.split("\n").map(&:strip).reject(&:empty?)
    lines.first(3).each do |line|
      next if line.match?(/resume|curriculum|vitae|cv|@/i) || line.length > 60
      words = line.split
      return line if words.length.between?(2,4) && words.all? { |w| w.match?(/\A[A-Z]/) }
    end
    "Unknown"
  end
end
