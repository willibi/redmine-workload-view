class TimeEntryFromUserHarvester < DataHarvester
  
  def initialize (full_period_start, full_period_end)
    @full_period_start = full_period_start
    @full_period_end = full_period_end
    super([])
  end
  
  def compute(user_id)
    results = []
    time_entries = TimeEntry.find(:all,
      :conditions => ["user_id = (:user) AND spent_on >= (:start) AND spent_on <= (:end)",
      {
                :user => user_id,
                :start => @full_period_start,
                :end => @full_period_end
      }])
    time_entries.each do |te|
      results.push(Result.new(te.spent_on,te.hours))
    end
    
    return results
  end
  
end