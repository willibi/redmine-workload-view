class ChargeController < ApplicationController
  unloadable
  
  require 'builder'
  require 'date'
  require 'rubygems'
  require 'json'
  
  layout 'base'
  
  attr_accessor :start
  attr_accessor :stop
  attr_accessor :period
  
  def read_observation_params
    
    @start = params[:start] ? Date.parse(params[:start]) : Date.today
    @stop = params[:stop] ? Date.parse(params[:stop]) : @start >> 1
    @period = params[:period] ? params[:period] : 'month'
    
  end
  
  def index
    @users = User.find(:all,
                       :order => "firstName")  
  end
  
  def user
    
    # TODO: add permission check  
    
    read_observation_params()
    
    login = params[:login] ? params[:login] : "admin" 
    
    @user = User.find(:all,
                      :conditions => ["login = ?", login],
                      :limit => 1).last
    
  end
  
  def userData
    
    # TODO: add permission check
    
    read_observation_params()
    
    user_id = params[:user]
    
    user = User.find_by_id(user_id)
    
    issues = Issue.find(:all,
      :conditions => [ "estimated_hours > 0 AND assigned_to_id = ?", user.id ])
    
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
    
    display = DataDisplayer.new("Workload")
    display.add_curve(wcurve)
    display.add_curve(tcurve)
    
    json = display.get_json
    
    send_data(json.to_json)
  end
  
  def project
    
    # TODO: add permission check
    
    read_observation_params()
    
    identifier = params[:project] ? params[:project] : "test-project"
    
    @project = Project.find(:all,
                      :conditions => ["identifier = ?", identifier],
                      :limit => 1).last
    
  end

  def projectData
    
    # TODO: add permission check
    
    read_observation_params()
    
    identifier = params[:project]
    
    project = Project.find(:all, :conditions => { :identifier => identifier } ).last
    
    issues = project.issues
    
    time_to_resolved = IssueTimeToStateHarvester.new('resolved', issues)
    compiler_time_to_resolved = DataCompiler.new(@start, @stop, @period, 'average')
    compiler_time_to_resolved.add_results(time_to_resolved.getResults)
    
    resolved_curve = CurveData.new(compiler_time_to_resolved)
    resolved_curve.label = "hours to resolved"
        
    display = DataDisplayer.new("Reactivity")
    display.add_curve(resolved_curve)
    
    json = display.get_json
    
    send_data(json.to_json)    
  end
end