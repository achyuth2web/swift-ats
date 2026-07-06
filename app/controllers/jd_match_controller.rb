class JdMatchController < ApplicationController
  def index
    @jobs       = current_user.visible_jobs.order(:title)
    @candidates = current_user.visible_candidates.order(:name)
  end
  def match
    jd = params[:jd_text].to_s.downcase

    job = current_user.visible_jobs.find(params[:job_id])

    candidates = current_user.visible_candidates
                            .where(job_id: job.id)

    jd_experience   = jd.match(/(\d+)\+?\s*(?:years|yrs)/i)&.captures&.first&.to_i
    required_skills = job.skills

    results = candidates.map do |candidate|

      skills = candidate.skills

      matched_skills =
        if required_skills.any?
          skills.select { |skill| required_skills.any? { |req| req.casecmp?(skill) } }
        else
          skills.select { |skill| jd.include?(skill.downcase) }
        end

      skill_score =
        if required_skills.any?
          (matched_skills.size.to_f / required_skills.size * 50)
        elsif skills.any?
          (matched_skills.size.to_f / skills.size * 50)
        else
          0
        end

      role_score =
        if candidate.role.present? &&
          jd.include?(candidate.role.downcase)
          20
        else
          0
        end

      designation_score =
        if candidate.designation.present? &&
          jd.include?(candidate.designation.downcase)
          10
        else
          0
        end

      department_score =
        if candidate.department.present? &&
          jd.include?(candidate.department.downcase)
          10
        else
          0
        end

      experience_score = 0

      if jd_experience.present? &&
        candidate.experience_years.present?

        experience_score =
          candidate.experience_years >= jd_experience ? 10 : 5
      end

      total_score =
        (
          skill_score +
          role_score +
          designation_score +
          department_score +
          experience_score
        ).round

      next if total_score.zero?

      {
        id: candidate.id,
        name: candidate.name,
        role: candidate.role,
        designation: candidate.designation,
        department: candidate.department,
        skills: skills,
        matched_skills: matched_skills,
        score: total_score,
        status: candidate.status,
        ctc: candidate.ctc_display
      }
    end.compact

    render json: results.sort_by { |r| -r[:score] }
  end
end
