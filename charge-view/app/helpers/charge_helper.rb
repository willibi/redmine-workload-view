module ChargeHelper
  
  def issue_count_open_issues(user)
    return open_issues(user).count
  end
  
  def open_issues(user)
    return Issue.find(:all,
                      :conditions => [ "assigned_to_id = ? AND `issue_statuses`.is_closed = 0", user.id ],
                      :include => [ :status ]
    )
  end
  
  def user_estimated_hours(user)
    hours = 0
    open_issues(user).each do |issue|
      unless issue.estimated_hours.nil?
        hours += issue.estimated_hours
      end
    end
    return hours
  end
  
end
