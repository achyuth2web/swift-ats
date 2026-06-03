class JdMatchController < ApplicationController
  def index
    @jobs       = current_user.visible_jobs.order(:title)
    @candidates = current_user.visible_candidates.order(:name)
  end
  def match
    jd   = params[:jd_text].to_s.downcase
    cands = current_user.visible_candidates
    results = cands.filter_map do |c|
      skills = c.skills
      matched = skills.select { |s| jd.include?(s.downcase) }

      next if matched.empty?

      score = [(matched.size.to_f / skills.size * 100).round, 100].min

      {
        id: c.id,
        name: c.name,
        role: c.role,
        skills: skills,
        matched_skills: matched,
        score: score,
        status: c.status,
        ctc: c.ctc_display
      }
    end
    render json: results.sort_by { |r| -r[:score] }
  end
end
