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
    @groups = Group.find(:all)
    
  end
  
  def user
    
    check_allowed
    
    read_observation_params()
    
    id = params[:id_select] ? params[:id_select] : "1" 
    
    @user = User.find(:first,
                      :conditions => ["id = ?", id],
                      :limit => 1)
    
  end
  
  def userData
    
    check_allowed
    
    read_observation_params()
    
    user_id = params[:id_select]
    
    current_user = User.find_by_id(user_id)
    
    issues = Issue.find(:all,
      :conditions => [ "estimated_hours > 0 AND assigned_to_id = ?", current_user.id ])
    
    compiler_time = DataCompiler.new(@start, @stop, @period, 'sum')
    
    user_time_entries = TimeEntryFromUserHarvester.new(compiler_time.get_full_period_start,compiler_time.get_full_period_end)
    user_time_entries.add(user_id)
    
    estimated_hours = EstimatedHoursHarvester.new(issues)
    
    display = DataDisplayer.new("Workload by " + @period)
    
    w = WorkDayComparator.new
    
    display.y_max = w.workabledays(
          compiler_time.get_full_period_start,
          compiler_time.get_end_period_date(@start)) * 8
    #workload_by_issues(compiler_time,estimated_hours,user_time_entries,display)
    
    display.y_max = 100.0
    normalized_workload(compiler_time,estimated_hours,user_time_entries,display)
    
  end
  
  def group
    
    check_allowed
    
    read_observation_params()
    
    id = params[:id_select] ? params[:id_select] : "1" 
    
    @group = Group.find(:first,
                      :conditions => ["id = ?", id],
                      :limit => 1)
    
  end
  
  def groupData
    
    check_allowed
    
    read_observation_params()
    
    group_id = params[:id_select]
    
    current_group = Group.find_by_id(group_id)
    
    compiler_time = DataCompiler.new(@start, @stop, @period, 'sum')
    user_time_entries = TimeEntryFromUserHarvester.new(compiler_time.get_full_period_start,compiler_time.get_full_period_end)
    estimated_hours = EstimatedHoursHarvester.new([])
    
    for current_user in current_group.users
      
      for issue in Issue.find(:all,
         :conditions => [ "estimated_hours > 0 AND assigned_to_id = ?", current_user.id ])
        estimated_hours.add(issue)
      end
      
      user_time_entries.add(current_user.id)
      
    end
    
    display = DataDisplayer.new("Workload by " + @period)
    
    workload_by_issues(compiler_time,estimated_hours,user_time_entries,display)
    
  end

  def normalized_workload_group(compiler_time,estimated_hours,user_time_entries,display,group_member)

    read_observation_params()
    
    compiler_estimated_hours = DataCompiler.new(@start, @stop, @period, 'sum')
    compiler_estimated_hours.add_results(estimated_hours.getResults)

    compiler_normalized = DataCompiler.new(@start, @stop, @period, 'sum')
    
    for r in compiler_estimated_hours.get_compiled_result
      w = WorkDayComparator.new()
      wd = w.workabledays(r.date, compiler_normalized.get_end_period_date(r.date))
      if wd == 0
        n = 0.0
      else
        n = r.value * 100 / ( 8.0 * wd * group_member )
      end
      norm_result = Result.new(r.date,n)
      compiler_normalized.add_result(norm_result)
    end

    wcurve = CurveData.new(compiler_normalized)
    wcurve.label = "Estimated workload (%)"
    wcurve.tool_tip = "workload #val#%"
    
    compiler_time.add_results(user_time_entries.getResults)
    
    tcurve = CurveData.new(compiler_time)
    tcurve.label = "Hours spent"
    tcurve.type = 'line'
    tcurve.line_colour = '#802020'
    tcurve.fill_colour = '#A04040'
    tcurve.on_right_axis = true
    tcurve.tool_tip = "#val#h spent"
    
    display.add_curve(wcurve)
    display.add_curve(tcurve)
    
    display.y_labels = "#val# %"
    display.y_labels_right = "#val# h"
    
    json = display.get_json
    
    send_data(json.to_json)

  end

  def normalized_workload(compiler_time,estimated_hours,user_time_entries,display)

    normalized_workload_group(compiler_time, estimated_hours, user_time_entries, display, 1)

  end

  def workload_by_issues(compiler_time,estimated_hours,user_time_entries,display)
   
    read_observation_params()
    
    compiler_estimated_hours = DataCompiler.new(@start, @stop, @period, 'sum')
    compiler_estimated_hours.add_results(estimated_hours.getResults)
    
    wcurve = CurveData.new(compiler_estimated_hours)
    wcurve.label = "Estimated hours"
    wcurve.tool_tip = "Estimated #val# h"
    
    compiler_time.add_results(user_time_entries.getResults)
    
    tcurve = CurveData.new(compiler_time)
    tcurve.label = "Hours spent"
    tcurve.type = 'line'
    tcurve.line_colour = '#802020'
    tcurve.fill_colour = '#A04040'
    tcurve.tool_tip = "#val#h spent"
    
    display.add_curve(wcurve)
    display.add_curve(tcurve)
    display.y_labels = "#val# h"
    
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
    
    identifier = params[:project_id] ? params[:project_id] : "test-project"
    
    @project = Project.find(:all,
                      :conditions => ["identifier = ?", identifier],
                      :limit => 1).last
    
  end
  
  def projectData
    
    #check_allowed()
    
    #read_observation_params()
    
    #identifier = params[:id_select]
    
    #current_project = Project.find(:first, :conditions => { :identifier => identifier } )
    
    #issues = current_project.issues
    
    #add_sub_project_issues(issues,current_project)
    
    #time_to_resolved = IssueTimeToStateHarvester.new('resolved', issues)
    #compiler_time_to_resolved = DataCompiler.new(@start, @stop, @period, 'average')
    #compiler_time_to_resolved.add_results(time_to_resolved.getResults)
    
    #resolved_curve = CurveData.new(compiler_time_to_resolved)
    #resolved_curve.label = "hours to resolved"
    
    #display = DataDisplayer.new("Reactivity by " + @period)
    #display.add_curve(resolved_curve)
    
    #estimated_hours = EstimatedHoursHarvester.new(issues)
    
    #display = DataDisplayer.new("Estimated hours by " + @period)
    
    #display.add_curve(estimated_hours)
    
    #json = display.get_json
    
    #send_data(json.to_json)

    check_allowed
    
    read_observation_params()
    
    identifier = params[:id_select]
    
    current_project = Project.find(:first, :conditions => { :identifier => identifier } )
    
    issues = current_project.issues    
    #issues = Issue.find(:all,
    #  :conditions => [ "estimated_hours > 0 AND assigned_to_id = ?", current_user.id ])
    
    compiler_time = DataCompiler.new(@start, @stop, @period, 'sum')
    
    user_time_entries = TimeEntryFromUserHarvester.new(compiler_time.get_full_period_start,compiler_time.get_full_period_end)
    for user in current_project.users
      user_time_entries.add(user.id)  
    end
    
    estimated_hours = EstimatedHoursHarvester.new(issues)
    
    display = DataDisplayer.new("Workload by " + @period)
    
    w = WorkDayComparator.new
    
    workload_by_issues(compiler_time,estimated_hours,user_time_entries,display)
    
    #display.y_max = 100.0
    #normalized_workload_group(compiler_time,estimated_hours,user_time_entries,display,current_project.users.size)

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
    @period = params[:period] ? params[:period] : 'month'
    parray = @period.split(',')
    if params[:commit] 
      for p in ['year','month','week','day']
        if params[p] and not parray.include?(p)
          parray.push(p)
        end
        if params[p].nil? and parray.include?(p)
          parray.delete(p)
        end
      end
      @period = ''
      sep = ''
      for p in parray
        @period += sep + p
        sep = ','
      end
    end
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