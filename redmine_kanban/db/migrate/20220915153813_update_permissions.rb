class UpdatePermissions < ActiveRecord::Migration[5.2]

  def change
    say_with_time "add project module Kanban & Checklists to defaults" do
      Setting.default_projects_modules += ['kanban', 'checklists']
    end

    # Enable Rate for every project.
    say_with_time "enable modules Kanban & Checklists for existing project" do
      projects = Project.all.to_a

      projects.each do |project|
        project.enable_module!(:kanban)
        project.enable_module!(:checklists)
      end

      projects.length
    end
  end


end