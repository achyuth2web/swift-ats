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

    results = candidates.filter_map do |c|
      skills = c.skills

      matched_skills = skills.select do |skill|
        jd.include?(skill.downcase)
      end

      next if matched_skills.empty?

      score =
        if skills.any?
          (matched_skills.size.to_f / skills.size * 100).round
        else
          0
        end

      {
        id: c.id,
        name: c.name,
        role: c.role,
        skills: skills,
        matched_skills: matched_skills,
        score: score,
        status: c.status,
        ctc: c.ctc_display
      }
    end

    render json: results.sort_by { |r| -r[:score] }
  end
end
