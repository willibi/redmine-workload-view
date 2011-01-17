class ChargeController < ApplicationController
  unloadable
  
  require "builder"
  
  layout 'base'
  
  def index
    #@users = User.find(:all,
    #                   :order => "firstName")
  end
  
  def data 
    users = User.find(:all,
                       :order => "firstName")
    json ='{ "title": { "text": "Titre graph" },
             "elements": [ 
               { "type": "bar_filled", 
                 "colour": "#E2D66A",
                 "outline-colour": "#577261",
                 "values": 
                  ['
    sep = ""
    users.each do |user|
      issue_count = issue_count_open_issues(user)
      if issue_count.nil?
        issue_ount = 0
      end
      json += sep + '{"top":' + issue_count.to_s+ ',"tip":"' + user.name + ' : #val#"}'
      sep = ","
    end
    json +=      '] } ],'
    json +=  '"y_axis":{"min": 0,"max": 200, "steps": 50},'
    json +=  '"bg_colour": "#FFFFFF"'
    json +='}'
    
    send_data(json)
    
  end
  
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
