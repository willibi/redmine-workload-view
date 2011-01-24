# This object represent a workload compilation entity
# it is build with an observation range where issue can
# be added. each issue will increase workload value at
# correct period.
#
# Workload can be computed with different period (year,
# month, week, day) inside a date range (all issue outside
# this initial range are ignored)

class Workload
  
  require 'date'
  
  attr_accessor :obs_start_date         # start of workload range
  attr_accessor :obs_end_date           # end of workload range
  attr_accessor :period_type            # one of 'year', 'month', 'week', 'day'
  
  WEEKDAY_NUMBERS = (1..5)              # define working day list 
                                        # 0 is sunday
                                        # 6 is saturday
  
  def initialize
    
    # result is an hash table with a list of period
    # each period { date => hours }
    @result_hours = {}
    
    @issue_list = []
    
    @max_hour_value = 0.0
    
    # used to execute data computation in case max hours is call before data
    @data_computed = false
    
  end
  
  # add an issue to workload
  def add_issue(issue)
    @issue_list.push(issue)
  end
  
  # compute and get data result
  def compute_data
    
    # init data result with period, obs_start_date and obs_end_date
    @result_hours = {}
    
    (@obs_start_date..@obs_end_date).each do |date|
      # get period start date according to period_type
      p_date = get_period_date(date)
      @result_hours[p_date] = 0.0
    end
    puts 'compute ' + @issue_list.length.to_s + ' issues'
    
    # parse each issue
    @issue_list.each do |issue|
      
      # compute issue start date
      if issue.start_date.nil?
        start_date = issue.created_on
      else
        start_date = issue.start_date
      end
      
      # compute issue stop date
      due_date = issue.due_before
      
      if due_date.nil?
        due_date = start_date + 1
      end
      
      # compute working days between the 2 date
      workabledays = (start_date..due_date).select{ |d| WEEKDAY_NUMBERS.include?( d.wday ) }.length.to_f
      if workabledays == 0
        workabledays = 1
      end
      
      # for each working days
       (start_date..due_date).each do |date|

        # do not add hours for not working day
        if WEEKDAY_NUMBERS.include?( date.wday )
        
          # get period start date according to period_type
          p_date = get_period_date(date)
          if p_date >= get_period_date(@obs_start_date) and p_date <= get_end_period_date(@obs_end_date)
           
            # add hours working date hours to result
            hours_for_day = issue.estimated_hours.to_f / workabledays
            if @result_hours[p_date].nil?
              @result_hours[p_date] = hours_for_day
            else
              @result_hours[p_date] += hours_for_day
            end
            
            # prepare max hour value
            if @result[p_date] > @max_hour_value
              @max_hour_value = @result[p_date] 
            end
          end
        end
      end
    end
    puts "result : " + @result.inspect
    @data_computed = true
    return @result
  end
  
  # return maximum hours. call compute_data if not already done
  def max_hour
    if @data_computed == false
      self.compute_data
    end
    return @max_hour_value
  end
  
  # return the first date of a period containing provided date
  def get_period_date(date)
    return case @period_type
      when 'year'  then Date.new(date.year,1,1)
      when 'month' then Date.new( date.year, date.month,1)
      when 'week'  then date - date.wday
      when 'day'   then date
    end
  end
  
  # return the lqst date of a period containing provided date
  def get_end_period_date(date)
    return case @period_type
      when 'year'  then Date.new(date.year + 1,1,1) - 1
      when 'month' then Date.new( (date>>1).year, (date>>1).month,1) - 1
      when 'week'  then date - date.wday + 6
      when 'day'   then date
    end
  end
  
end
