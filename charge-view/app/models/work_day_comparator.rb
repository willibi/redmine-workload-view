class WorkDayComparator
  
  attr_accessor :work_days
  attr_accessor :open_hour
  attr_accessor :close_hour
  
  def initialize
    @work_week_days = (1..5)
    @open_hour = 8
    @close_hour = 17
  end
  
  def worked_hours_by_day ()
    return @close_hour - @open_hour
  end
  
  def workabledays (start,stop)
    # convert input in date to avoid building range with time (cause 1s increment in place
    # of 1 day)
    start_date = Date.new(start.year,start.month,start.day)
    stop_date = Date.new(stop.year,stop.month,stop.day)
    return (start_date..stop_date).select{ |d| @work_week_days.include?( d.wday ) }.length.to_f
  end
  
  # compute the number of open hours between this 2 time
  def work_hours(start,stop)
    # compute working days between the 2 date
    wd = workabledays(start,stop)
    
    # compute hours between start date and close hours
    start_time = @close_hour - ( ( start - day_ref(start) ) / 3600.0 )
    # cannot be negative
    if start_time < 0.0
      start_time = 0.0
    end
    # cannot be greater than a complete day
    if start_time > (@close_hour - @open_hour)
      start_time = @close_hour - @open_hour
    end
    
    # compute hours between open hours and stop date
    stop_time = ( ( stop - day_ref(stop) ) / 3600.0 ) - @open_hour
    # cannot be negative
    if stop_time < 0.0
      stop_time = 0.0
    end
    # cannot be greater than a complete day
    if stop_time > (@close_hour - @open_hour)
      stop_time = @close_hour - @open_hour
    end
    
    result = 0.0
    
    if wd == 0
      result = start_time + stop_time - (@close_hour - @open_hour)
    else
      result = start_time + stop_time + (@close_hour - @open_hour) * wd
    end
    
    return result
    
  end
  
  def day_ref(d)
    return Time.local(d.year,d.month,d.day)
  end
end