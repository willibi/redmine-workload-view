#
# based on issue object produce estimated_hours distribute
# day by day in a range. Range is computed based on issue 
# due_date
#
class EstimatedHoursHarvester < DataHarvester
  
  WEEKDAY_NUMBERS = (1..5)              # define working day list 
  # 0 is sunday
  # 6 is saturday
  
  def initialize
    super
  end

  def initialize(o)
    super(o)
  end
  
  # this method is an example one. It should be
  # override for a more interesting use
  # the return an array of Result object
  def compute(issue)
    
    results = []
    
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
      
      # do not add hours for not working day and issues with sub issues
      if WEEKDAY_NUMBERS.include?( date.wday ) and not issue.children?
        
        # add hours working date hours to result
        hours_for_day = issue.estimated_hours.to_f / workabledays        
        results.push(Result.new(date,hours_for_day))
        
      end
    end      
    
    return results
  end
  
end