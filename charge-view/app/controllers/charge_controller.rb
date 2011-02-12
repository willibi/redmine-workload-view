class ChargeController < ApplicationController
  unloadable
  
  require 'builder'
  require 'date'
  require 'rubygems'
  
  layout 'base'
  
  attr_accessor :start
  attr_accessor :stop
  attr_accessor :period
  
  def index
    
    check_allowed
    
    read_observation_params()
    
  end

  def user_selection

    check_allowed
    
    read_observation_params()
    
    @users = User.find(:all,
                       :order => "firstName")
  
  end
  
  def user
    
    check_allowed
    
    read_observation_params()
    
    id = params[:id_select] ? params[:id_select] : "1" 
    
    @user = User.find(:all,
                      :conditions => ["id = ?", id],
                      :limit => 1).last
    
    
  end
  
  def userData
    
    check_allowed
    
    read_observation_params()
    
    user_id = params[:id_select]
    
    current_user = User.find_by_id(user_id)
    
    issues = Issue.find(:all,
      :conditions => [ "estimated_hours > 0 AND assigned_to_id = ?", current_user.id ])
    
    estimated_hours = EstimatedHoursHarvester.new(issues)
    compiler_estimated_hours = DataCompiler.new(@start, @stop, @period, 'sum')
    compiler_estimated_hours.add_results(estimated_hours.getResults)
    
    wcurve = CurveData.new(compiler_estimated_hours)
    wcurve.label = "Estimated hours"
    
    compiler_time = DataCompiler.new(@start, @stop, @period, 'sum')
    user_time_entries = TimeEntryFromUserHarvester.new(compiler_time.get_full_period_start,compiler_time.get_full_period_end)
    user_time_entries.add(user_id)
    compiler_time.add_results(user_time_entries.getResults)
    
    tcurve = CurveData.new(compiler_time)
    tcurve.label = "Hours spent"
    tcurve.type = 'line'
    tcurve.line_colour = '#802020'
    tcurve.fill_colour = '#A04040'
    
    display = DataDisplayer.new("Workload by " + @period)
    display.add_curve(wcurve)
    display.add_curve(tcurve)
    
    json = display.get_json
    
    send_data(json.to_json)
  end
  
  def project_selection
  
    check_allowed
    
    read_observation_params()
    
    @projects = Project.find(:all, :order => "name") 
    
  end
  
  def project
    
    check_allowed()
    
    read_observation_params()
    
    identifier = params[:id_select] ? params[:id_select] : "test-project"
    
    @project = Project.find(:all,
                      :conditions => ["identifier = ?", identifier],
                      :limit => 1).last
    
  end
  
  def projectData
    
    check_allowed()
    
    read_observation_params()
    
    identifier = params[:id_select]
    
    current_project = Project.find(:first, :conditions => { :identifier => identifier } )
    
    issues = current_project.issues
    
    add_sub_project_issues(issues,current_project)
    
    time_to_resolved = IssueTimeToStateHarvester.new('resolved', issues)
    compiler_time_to_resolved = DataCompiler.new(@start, @stop, @period, 'average')
    compiler_time_to_resolved.add_results(time_to_resolved.getResults)
    
    resolved_curve = CurveData.new(compiler_time_to_resolved)
    resolved_curve.label = "hours to resolved"
    
    display = DataDisplayer.new("Reactivity by " + @period)
    display.add_curve(resolved_curve)
    
    json = display.get_json
    
    send_data(json.to_json)    
  end
  
  private
  
  def get_sub_projects(project)
    return Project.find_by_sql(
    ["SELECT `projects`.`identifier`
        FROM `projects`
        WHERE `projects`.`parent_id` = 
          (
            SELECT `projects`.`id` 
            FROM `projects` 
            WHERE `projects`.`identifier` = ?
            AND `projects`.`status` = 1
          )",project.identifier])
  end
  
  def add_sub_project_issues(issues,current_project)
    current_project
    get_sub_projects(current_project).each do |p|
       p.issues.each do |i|
         issues.push(i)
       end
       add_sub_project_issues(issues, p)
    end
  end
  
  def read_observation_params()
    
    @start = params[:start] ? Date.parse(params[:start]) : Date.today
    @stop = params[:stop] ? Date.parse(params[:stop]) : @start >> 1
    @period = params[:period] ? params[:period] : 'year,month,week,day'

  end
  
  def check_allowed()
    if User.current.allowed_to?(:view_charge, nil, :global => true)
      # user allowed
      return
    else
      # go to 403 error page
      render_403
    end
  end
end