# class used to get a list of Result compiled in a list
# of ordered Result define by a start end stop date and
# a collection of Results.
class DataCompiler
  
  require 'date'
  
  attr_reader :obs_start_date         # start of workload range
  attr_reader :obs_end_date           # end of workload range
  attr_reader :period_type            # one of 'year', 'month' (default), 'week', 'day'
  attr_reader :input_results          # list of Result object to be compiled
  attr_reader :compilation_mode       # one of 'sum' (default), 'percent', 'average'
  attr_reader :compiled               # boolean value to define if data has been compiled or not
  
  # this attributes are only set after get_compiled_result call
  attr_reader :max_value              # provide maximum value of the compiled data
  
  # constructors
  
  def initialize(obs_start_date, obs_end_date, period_type, compilation_mode)
    
    @obs_start_date = obs_start_date
    @obs_end_date = obs_end_date
    @period_type = period_type
    @compilation_mode = compilation_mode
    @input_results = []
    @compiled = false
    
    @max_value = 0.0
    
    # hash used to organized results
    @slots = {}
    
    # init data result with period, obs_start_date and obs_end_date
     (@obs_start_date..@obs_end_date).each do |date|
      # get period start date according to period_type
      p_date = get_period_date(date)
      if @slots.has_key?(p_date) == false
        @slots[p_date] = Result.new(p_date,0.0)
      end
    end
  end
  
  def dates
    return @slots.keys
  end
  
  # use this method to add a result to the compiled datas
  # return true if result can be compiled (in the observation
  # range)
  def add_result (result)
    # do not add result with date outside observation date 
    if @slots.has_key?(get_period_date(result.date))
      @input_results.push(result)
      return true
    end
    #puts "@@@@@@@@@@@@@@ cannot add " + result.inspect
    return false
  end
  
  # use this if you have an array of result
  def add_results (results)
    for result in results
      add_result(result)
    end
  end
  
  # compute and return list of compiled result
  def get_compiled_result
        
    if @compiled == false
      
      all_result_values_sum = 0.0
      
      # add all result in coresponding period to compute all periods
      for result in input_results
        all_result_values_sum += result.value
        p_date = get_period_date(result.date)
        @slots[p_date].value += result.value
        @slots[p_date].number_of_initial_value += 1
      end
      
      if @compilation_mode == 'average'
        for slot in @slots.values
          if slot.number_of_initial_value != 0
            slot.value = slot.value / slot.number_of_initial_value
          end
        end
      end
      
      if @compilation_mode == 'percent'
        for slot in @slots.values
          if all_result_values_sum != 0
            slot.value = slot.value * 100.0 / all_result_values_sum
          end
        end
      end
      
      # compute compiled max value
      for slot in @slots.values
        if slot.value > @max_value
          @max_value = slot.value
        end
      end
      
      @compiled = true
      
    end
    
    final_result = []
    for date in @slots.keys.sort
      final_result.push(@slots[date])
    end
    return final_result
    
  end
  
  # return the first date of a period containing provided date
  def get_period_date(date)
    return case @period_type
      when 'year'  then Date.new(date.year,1,1)
      when 'month' then Date.new( date.year, date.month,1)
      when 'week'  then Date.parse((date - date.wday).strftime("%Y-%m-%d"))
      when 'day'   then Date.parse((date).strftime("%Y-%m-%d"))
    end
  end
  
  # return the last date of a period containing provided date
  def get_end_period_date(date)
    return case @period_type
      when 'year'  then Date.new(date.year + 1,1,1) - 1
      when 'month' then Date.new( (date>>1).year, (date>>1).month,1) - 1
      when 'week'  then Date.parse((date - date.wday + 6).strftime("%Y-%m-%d"))
      when 'day'   then Date.parse((date).strftime("%Y-%m-%d"))
    end
  end
  
  def get_full_period_start
    return get_period_date(@obs_start_date)
  end
  
  def get_full_period_end
    return get_end_period_date(@obs_end_date)
  end
  
end