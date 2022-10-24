require_dependency 'issue_query'

module RedmineKanban
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method :base_scope_without_kanban, :base_scope
          alias_method :base_scope, :base_scope_with_kanban

          alias_method :issues_without_kanban, :issues
          alias_method :issues, :issues_with_kanban

          alias_method :issue_ids_without_kanban, :issue_ids
          alias_method :issue_ids, :issue_ids_with_kanban

          alias_method :statement_without_kanban_fields, :statement
          alias_method :statement, :statement_with_kanban_fields

          alias_method :available_filters_without_kanban_fields, :available_filters
          alias_method :available_filters, :available_filters_with_kanban_fields
        end
      end

      module InstanceMethods
        def base_scope_with_kanban
          base_scope_without_kanban.left_joins(:kanban_issue)
        end

        def issues_with_kanban(options = {})
          order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)
          # The default order of IssueQuery is issues.id DESC(by IssueQuery#default_sort_criteria)
          unless ["#{Issue.table_name}.id ASC", "#{Issue.table_name}.id DESC"].any?{|i| order_option.include?(i)}
            order_option << "#{Issue.table_name}.id DESC"
          end

          scope = Issue.visible.
            joins(:status, :project).
            left_joins(:kanban_issue).
            preload(:priority).
            where(statement).
            includes(([:status, :project, :kanban_issue] + (options[:include] || [])).uniq).
            where(options[:conditions]).
            order(order_option).
            joins(joins_for_order_statement(order_option.join(','))).
            limit(options[:limit]).
            offset(options[:offset])

          scope = scope.preload([:tracker, :author, :assigned_to, :fixed_version, :category, :attachments] & columns.map(&:name))
          if has_custom_field_column?
            scope = scope.preload(:custom_values)
          end

          issues = scope.to_a

          if has_column?(:spent_hours)
            Issue.load_visible_spent_hours(issues)
          end
          if has_column?(:total_spent_hours)
            Issue.load_visible_total_spent_hours(issues)
          end
          if has_column?(:last_updated_by)
            Issue.load_visible_last_updated_by(issues)
          end
          if has_column?(:relations)
            Issue.load_visible_relations(issues)
          end
          if has_column?(:last_notes)
            Issue.load_visible_last_notes(issues)
          end
          issues
        rescue ::ActiveRecord::StatementInvalid => e
          raise StatementInvalid.new(e.message)
        end

        def issue_ids_with_kanban(options = {})
          order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)
          # The default order of IssueQuery is issues.id DESC(by IssueQuery#default_sort_criteria)
          unless ["#{Issue.table_name}.id ASC", "#{Issue.table_name}.id DESC"].any?{|i| order_option.include?(i)}
            order_option << "#{Issue.table_name}.id DESC"
          end

          Issue.visible.
            joins(:status, :project).
            left_joins(:kanban_issue).
            where(statement).
            includes(([:status, :project, :kanban_issue] + (options[:include] || [])).uniq).
            references(([:status, :project] + (options[:include] || [])).uniq).
            where(options[:conditions]).
            order(order_option).
            joins(joins_for_order_statement(order_option.join(','))).
            limit(options[:limit]).
            offset(options[:offset]).
            pluck(:id)
        rescue ::ActiveRecord::StatementInvalid => e
          raise StatementInvalid.new(e.message)
        end

        def sql_for_block_reason_field(field, operator, v)
          db_table = KanbanIssue.table_name
          sql_for_field(field, operator, v, db_table, 'block_reason', true)
        end

        def statement_with_kanban_fields
          # filter  = filters.delete 'block_reason'
          statement_without_kanban_fields || ''
        end

        def available_filters_with_kanban_fields
          available_filters_without_kanban_fields
          add_available_filter('block_reason', type: :text, name: l(:filters_label_block_reason))
        end
      end
    end
  end
end

unless IssueQuery.included_modules.include?(RedmineKanban::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineKanban::Patches::IssueQueryPatch)
end
