class ChargeController < ApplicationController
  unloadable
  
  require 'builder'
  require 'date'
  require 'rubygems'
  require 'json'
  
  layout 'base'
  
  def index
    
    # TODO: add permission check  
    
    @users = User.find(:all,
                       :order => "firstName",
                       :limit => 40)
  end
  
  def data
    
    # TODO: add permission check
    
    user = User.find_by_id(params[:user])
    issues = Issue.find(:all,
                        :conditions => [ "estimated_hours > 0 AND assigned_to_id = ?", user.id ])
    workload = Workload.new
    workload.add_user(user)
    workload.compute_time_entry
    workload.obs_start_date = Date.parse(params[:start])
    workload.obs_end_date = Date.parse(params[:stop])
    workload.period_type = params[:period]
    # add issues take in account for workload computation
    issues.each do |issue|
      workload.add_issue(issue)
    end
    # compute datas from issue list 
    datas = workload.compute_data
    times = workload.time_entries
    # compute vertical axis limit and step
    step = ((workload.max_hour.to_f/5.0).divmod(10)[0]+1)*10
    max = (workload.max_hour.to_f.divmod(step)[0]+1)*step
    
    values = []
    time_values = []
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
      
      # add data and tip (popup on bar)  
      values.push( { "top" => datas[date].to_s , "tip" => print_date + ' : #val#' } )
      # add horizontal label for this bar
      labels.push( print_date )
      # add time entry data
      time_values.push(times[date])
      puts("add " + times[date].to_s)
    end
    
    # buil json object defining graph
    json ={ "title" => { "text" => "Workload for " + user.name },
            "elements" => [ 
      { "type" => "bar_filled", 
                 "colour" => "#E2D66A",
                 "outline-colour" => "#577261",
                 "values" => values }, 
      { "type" => "line", 
                 "values" => time_values, 
                 "dot-style" => { "type" => "solid-dot", 
                                  "dot-size" => 3, 
                                  "halo-size" => 1, 
                                  "colour" => "#3D5C56" }, 
                 "width" => 2, 
                 "colour" => "#3D5C56" }
      ],
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