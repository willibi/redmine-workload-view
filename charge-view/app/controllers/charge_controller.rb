class ChargeController < ApplicationController
  unloadable
  
  require 'builder'
  require 'date'
  require 'rubygems'
  require 'json'
  
  layout 'base'
  
  def index
    @users = User.find(:all,
                       :order => "firstName",
                       :limit => 40)
  end
  
  def data
    user = User.find_by_id(params[:user])
    issues = Issue.find(:all,
                        :conditions => [ "estimated_hours > 0 AND assigned_to_id = ?", user.id ])
    workload = Workload.new
    workload.obs_start_date = Date.parse(params[:start])
    workload.obs_end_date = Date.parse(params[:stop])
    workload.period_type = params[:period]
    puts 'create workload : ' + workload.inspect
    issues.each do |issue|
      workload.add_issue(issue)
    end
    datas = workload.compute_data
    step = ((workload.max_hour.to_f/5.0).divmod(10)[0]+1)*10
    max = (workload.max_hour.to_f.divmod(step)[0]+1)*step
    values = []
    labels = []
    datas.keys.sort.each do |date|
      # compute label according to period type
      print_date = case workload.period_type
        when 'year' 
        date.year.to_s
        when 'month' 
        date.year.to_s + "-" + date.month.to_s
        when 'week' 
        date.to_s
        when 'day' 
        date.to_s
      end
      
      
      values.push( { "top" => datas[date].to_s , "tip" => print_date + ' : #val#' } )
      labels.push( print_date ) 
    end
    json ={ "title" => { "text" => "Workload for " + user.name },
            "elements" => [ 
      { "type" => "bar_filled", 
                 "colour" => "#E2D66A",
                 "outline-colour" => "#577261",
                 "values" => values
      } ],
            "y_axis" => { "min" => 0,"max" => max.to_s, "steps" => step.to_s },
            "x_axis" => { "labels" => { "rotate" => -45, "labels"  => labels} }, 
            "bg_colour" => "#FFFFFF" 
    }
    
    send_data(json.to_json)
    
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