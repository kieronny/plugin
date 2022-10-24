module RedmineKanban
  module Patches
    module SettingPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do
          class << self
            alias_method 'plugin_redmine_kanban=_without', :plugin_redmine_kanban=
            alias_method :plugin_redmine_kanban=, 'plugin_redmine_kanban=_with'
          end
        end
      end

      module ClassMethods
        define_method('plugin_redmine_kanban=_with') do |settings|
          ids= []
          if !settings[:project_ids].nil?
            ids = settings[:project_ids].map{ |id| id.to_i}
          end
          Project.all.each do |project|
            if (ids.include?(project.id))
              project.enable_module!('kanban')
            else
              project.disable_module!('kanban')
            end
            send('plugin_redmine_kanban=_without', settings)
          end
        end
      end
    end
  end
end

unless Setting.included_modules.include?(RedmineKanban::Patches::SettingPatch)
  Setting.send(:include, RedmineKanban::Patches::SettingPatch)
end
