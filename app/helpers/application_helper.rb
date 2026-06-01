module ApplicationHelper
  def status_badge_class(status)
    {"New"=>"badge-blue","Screening"=>"badge-amber","Interview"=>"badge-purple",
     "Offer"=>"badge-green","Rejected"=>"badge-red","Hired"=>"badge-green",
     "Open"=>"badge-green","Closed"=>"badge-red","Reopened"=>"badge-amber"}[status] || "badge-gray"
  end
end
