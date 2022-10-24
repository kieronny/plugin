
require 'redmine'

Redmine::Plugin.register :redmine_kanban do
  name 'Redmine Kanban plugin'
  author 'Roman Petrenko'
  description 'This is Kanban and checklist plugin for redmine'
  version '1.1.3'
  url 'https://redmine-kanban.com'

  project_module :kanban do
    permission :view_kanban, {:kanban => [:index, :get_issues, :get_issue, :set_issue_status ], :kanban_query => [:index] }
  end

  project_module :checklists do
    permission :edit_checklists, { :questionlist => [:create, :update, :delete] }
  end

  menu :project_menu, :kanban, { controller: 'kanban', action: 'index' }, caption: :label_kanban, after: :activity, param: :project_id
  menu :top_menu, :kanban, { controller: 'kanban', action: 'index', :project_id => nil }, caption: :label_kanban, first: true ,
        :if => Proc.new{ User.current.allowed_to?({:controller => 'kanban', :action => 'index'}, nil, {:global => true}) && Setting.plugin_redmine_kanban['kanban_show_in_top_menu'].to_i > 0  }

  menu :application_menu, :redmine_kanban, { controller: 'kanban', action: 'index' }, caption: :label_kanban, 
        :if => Proc.new{ User.current.allowed_to?({:controller => 'kanban', :action => 'index'}, nil, {:global => true})  && Setting.plugin_redmine_kanban['kanban_show_in_app_menu'].to_i > 0 }

  menu :admin_menu, :redmine_kanban, {controller: 'settings', action: 'plugin', id: 'redmine_kanban'}, caption: :label_kanban, html: {class: 'icon'}

  settings :default => {:empty => true}, :partial => 'settings/kanban/index'

end

if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/lib') }
end

require File.dirname(__FILE__) + '/lib/redmine_kanban'
