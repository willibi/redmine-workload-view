# a simple object use to represent a point to be
# displayed in a chart graph
class Result
  attr_accessor :date
  attr_accessor :value
  attr_accessor :number_of_initial_value
  
  def initialize(date,value)
    @date = date
    @value = value
    @number_of_initial_value = 0
  end
  
end