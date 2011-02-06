# class used to transform a list of curve data to a json object
# ready to be used in open flash chart
class DataDisplayer
  attr_accessor :title
  
  def initialize (title)
    @title = title
    @curves = []
  end
  
  def add_curve(curve)
    @curves.push(curve)
  end
  
  def get_json
    
    labels = []
    labels_empty = true
    
    elements = []
    max_value = 0.0
    
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
        values.push(result.value)
        
        # compute max value
        if result.value > max_value
          max_value = result.value
        end
      end
      labels_empty = false
      
      # build curve definition for json output
      if curve.type == 'bar'
        e = { "type" => "bar_filled", 
                 "colour" => curve.fill_colour,
                 "outline-colour" => curve.line_colour,
                 "on-show" => { "type"=> "grow-up", "cascade"=> 2.5, "delay"=> 0 },
                 "text" => curve.label,
                 "values" => values }
      end
      if curve.type == 'line'
        e = { "type" => "line",
                 "colour" => curve.line_colour,
                 "dot-style" => { "type" => "solid-dot", 
                                  "dot-size" => 3, 
                                  "halo-size" => 1, 
                                  "colour" => curve.fill_colour },
                 "on-show" => { "type"=> "grow-up", "cascade"=> 2.5, "delay"=> 0 },
                 "width" => 2, 
                 "text" => curve.label,
                 "values" => values }
      end
      elements.push(e)
    end
    
    # compute vertical axis limit and step
    step = ((max_value.to_f/5.0).divmod(10)[0]+1)*10
    max = (max_value.to_f.divmod(step)[0]+1)*step
    
    # build json object defining graph
    json ={ "title" => { "text" => @title },
            "elements" => elements,
            "y_axis" => { "min" => 0,"max" => max.to_s, "steps" => step.to_s },
            "x_axis" => { "labels" => { "rotate" => -45, "labels"  => labels} }, 
            "bg_colour" => "#FFFFFF" 
    }
    
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