# used to describe a single curve
class CurveData
  attr_accessor :type              # one of 'bar' (default), 'line'
  attr_accessor :fill_colour       # points colour or bar fill (default #E2D66A)
  attr_accessor :line_colour       # line colour or bar outline (default #577261)
  attr_accessor :label             # label of the curve
  attr_accessor :data_compiler     # associate data compiler used to retreive datas
  attr_accessor :on_right_axis
  attr_accessor :tool_tip
  
  def initialize(data_compiler)
    @type = 'bar'
    @fill_colour = "#E2D66A"
    @line_colour = "#577261"
    @label = ''
    @data_compiler = data_compiler
    @on_right_axis = false
    @tool_tip = nil
  end
end