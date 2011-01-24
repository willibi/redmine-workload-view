require 'redmine'

Redmine::Plugin.register :project_charge do
  name 'Redmine Workload plugin'
  author 'Willi Bi'
  description 'Compute and display Human charge on project'
  version '0.0.0'

  requires_redmine :version_or_higher => '0.8.0'

  project_module :charges do
    permission :view_charge, { :charge => :index }
  end

  menu :top_menu, 
    :charges, 
    {
      :controller => 'charge', 
      :action => 'index' 
    }, 
    :caption => 'Charge'
  
end