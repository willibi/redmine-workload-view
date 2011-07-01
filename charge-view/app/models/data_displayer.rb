# class used to transform a list of curve data to a json object
# ready to be used in open flash chart
class DataDisplayer
  attr_accessor :title
  attr_accessor :y_max
  attr_accessor :y_min
  attr_accessor :y_max_right
  attr_accessor :y_min_right
  attr_accessor :y_labels
  attr_accessor :y_labels_right
  
  
  def initialize (title)
    @title = title
    @curves = []
    @y_max = nil
    @y_min = nil
    @y_max_right = nil
    @y_min_right = nil
    @have_right_axis = false
    @y_labels = nil
    @y_labels_right = nil
  end
  
  def add_curve(curve)
    @curves.push(curve)
    if curve.on_right_axis
      @have_right_axis = true
    end
  end
  
  def get_json
    
    # TODO compute min axis for negative values
    
    labels = []
    labels_empty = true
    
    elements = []
    max_value = 0.0
    max_value_right = 0.0
    
    # for each curve build corresponding element
    for curve in @curves
      
      # build curve value
      values = []
      for result in curve.data_compiler.get_compiled_result
        
        # if not already done build label 
        # (all curve data_compiler shall have same observation range
        # and same period type !)
        if labels_empty
          labels.push(print_date(result.date, curve.data_compiler.period_type)) 
        end
        
        # add value for current result
        if curve.tool_tip and curve.type == 'line'
          values.push({ "value" => result.value, "tip" => curve.tool_tip })
        else
          values.push(result.value)
        end
        
        # compute max value
        if curve.on_right_axis
          if result.value > max_value_right
            max_value_right = result.value
          end          
        else
          if result.value > max_value
            max_value = result.value
          end
        end
      end
      labels_empty = false
      
      # build curve definition for json output
      if curve.type == 'bar'
        e = { "type" => "bar_filled", 
                 "colour" => curve.fill_colour,
                 "outline-colour" => curve.line_colour,
                 "text" => curve.label,
                 "values" => values }
      end
      
      if curve.type == 'line'
        e = { "type" => "line",
                 "colour" => curve.line_colour,
                 "dot-style" => { "type" => "dot", 
                                  "dot-size" => 3, 
                                  "halo-size" => 1, 
                                  "colour" => curve.fill_colour },
                 "width" => 2, 
                 "text" => curve.label,
                 "values" => values }
      end
      
      if curve.on_right_axis
        e["axis"] = "right"
      end
      
      if curve.tool_tip and curve.type != 'line'
        e["tip"] = curve.tool_tip
      end
      
      elements.push(e)
    end
    
    if @y_max.nil? or @y_max < max_value
      # compute vertical axis limit and step
      step = ((max_value.to_f/5.0).divmod(10)[0]+1)*10
      @y_max = (max_value.to_f.divmod(step)[0]+1)*step
    else
      step = (@y_max.to_f/5.0)
    end

    if @y_max_right.nil? or @y_max_right < max_value_right
      # compute vertical axis limit and step
      step_right = ((max_value_right.to_f/5.0).divmod(10)[0]+1)*10
      @y_max_right = (max_value_right.to_f.divmod(step_right)[0]+1)*step_right
    else
      step_right = (@y_max_right.to_f/5.0)
    end

    # build json object defining graph
    json ={ #"title" => { "text" => @title },
            "elements" => elements,
            "y_axis" => { "min" => @y_min.nil? ? 0 : @y_min.to_s,
                          "max" => @y_max.to_s, 
                          "steps" => step.to_s },
            "x_axis" => { "labels" => { "rotate" => -45, "labels"  => labels} }, 
            "bg_colour" => "#FFFFFF" 
    }
    if @have_right_axis
      json["y_axis_right"] = { "min" => @y_min_right.nil? ? 0 : @y_min_right.to_s,
                               "max" => @y_max_right.to_s, 
                               "steps" => step_right.to_s }
    end
    
    if @y_labels
      json["y_axis"]["labels"] = {"text" => @y_labels}
    end
    
    if @y_labels_right
      json["y_axis_right"]["labels"] = {"text" => @y_labels_right}
    end
    
    return json
    
  end
  
  def print_date(date,period_type)
    return case period_type
      when 'year' 
      date.year.to_s
      when 'month' 
      date.year.to_s + "-" + date.month.to_s
      when 'week' 
      date.to_s
      when 'day' 
      date.to_s
    end
  end
end