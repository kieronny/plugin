require_dependency 'issue'

module RedmineKanban
  module Patches
    module IssuePatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          has_one :kanban_issue, :dependent => :destroy

          has_many :questionlists, dependent: :destroy

          safe_attributes 'kanban_issue_attributes', :if => lambda { |issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }

          accepts_nested_attributes_for :kanban_issue, :update_only => true

        end
      end

      module ClassMethods
      end

      module InstanceMethods

        def kanban_issue
          super || build_kanban_issue
        end

        def day_in_state
          change_time = journals.joins(:details).where(
            :journals => { :journalized_id => id, :journalized_type => 'Issue' },
            :journal_details => { :prop_key => 'status_id' }
          ).order('created_on DESC').first
          change_time.created_on
        rescue
          created_on
        end

        def last_comment
          journals.where("notes <> ''").order("#{Journal.table_name}.id ASC").last
        end

        def block_reason
          @block_reason ||= kanban_issue ? kanban_issue.block_reason : nil
        end

        def estimated_complexity
          @estimated_complexity ||= kanban_issue ? kanban_issue.estimated_complexity : nil
        end

        def blocked_at
          @blocked_at ||= kanban_issue ? kanban_issue.blocked_at : nil
        end

        def sort_order
          kanban_issue.sort_order
        end

        def set_sort_order(order)
          kanban_issue.sort_order = order
        end

        def can_add_checklist?(user = User.current)
          # pp user.roles_for_project(project)
          user.allowed_to?(:edit_checklists, project)
        end

      end
    end

  end
end

unless Issue.included_modules.include?(RedmineKanban::Patches::IssuePatch)
  Issue.send(:include, RedmineKanban::Patches::IssuePatch)
end
