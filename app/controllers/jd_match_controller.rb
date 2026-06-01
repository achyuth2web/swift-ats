class JdMatchController < ApplicationController
  def index
    @jobs       = current_user.visible_jobs.order(:title)
    @candidates = current_user.visible_candidates.order(:name)
  end
  def match
    jd   = params[:jd_text].to_s.downcase
    cands = current_user.visible_candidates
    results = cands.map do |c|
      skills   = c.skills
      matched  = skills.select { |s| jd.include?(s.downcase) }
      score    = skills.any? ? [(matched.size.to_f / skills.size * 100).round, 100].min : 0
      bonus    = (c.role.to_s+" "+c.designation.to_s).downcase.split
                   .count { |w| jd.include?(w) && w.length > 3 } * 5
      score    = [score + bonus, 100].min
      { id: c.id, name: c.name, role: c.role, skills: skills,
        matched_skills: matched, score: score, status: c.status, ctc: c.ctc_display }
    end
    render json: results.sort_by { |r| -r[:score] }
  end
end
