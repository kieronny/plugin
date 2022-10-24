module KanbanHelper
  include QueriesHelper
  include QuestionlistHelper

  def format_issue_base(issue)
    item ={}
    item[:id] = issue.id
    item[:subject] = issue.subject
    item[:status_id] = issue.status.id
    item[:status_name] = issue.status.name
    item[:block_reason] = issue.kanban_issue ? issue.kanban_issue.block_reason : nil
    item[:blocked_at] = issue.kanban_issue ? issue.kanban_issue.blocked_at : nil
    item[:updated_on] = issue.updated_on
    item
  end


  def format_issues(items)
    result = []
    items.each do |issue|
      item = format_issue_base(issue)

      if @query.has_column?(:tracker)
        item[:tracker] = issue.tracker.name
        item[:tracker_id] = issue.tracker.id
      end


      if @query.has_column?(:project)
        item[:project_id] = issue.project.id
        item[:project_name] = issue.project.name
      end

      @query.has_column?(:created_on) && item[:created_on] = issue.created_on
      @query.has_column?(:author) && item[:author] = user_name_or_anonymous(issue.author)
      # @query.has_column?(:assigned_to) &&

      if @query.has_column?(:priority)
        item[:priority_id] = issue.priority_id
        item[:priority_name] = issue.priority.name
      end

      @query.has_column?(:spent_hours) && item[:spent_hours] = issue.spent_hours

      if @query.has_column?(:parent) && !issue.parent_issue_id.nil?
        item[:parent_id] = issue.parent_issue_id
        item[:parent_name] = Issue.find_by(:id=> issue.parent_issue_id).nil? ? "" : Issue.find_by(:id=> issue.parent_issue_id).subject
      end
      @query.has_column?(:updated_on) && item[:updated_on] = issue.updated_on
      @query.has_column?(:total_estimated_hours) && item[:total_estimated_hours] = issue.total_estimated_hours
      @query.has_column?(:subject) && item[:subject] = issue.subject
      @query.has_column?(:is_private) && item[:is_private] = issue.is_private?

      if @query.has_column?(:assigned_to) && !issue.assigned_to_id.nil?
        user = user_or_anonymous(issue.assigned_to)
        item[:assigned_to_id] = issue.assigned_to_id
        item[:assigned_to] = user.name
        item[:assigned_to_type] = user.type
      end

      if issue.blocked?
        blocks = []
        issue.relations.select {|ir| ir.relation_type == 'blocks' && !ir.issue_from.closed? && ir.issue_to.id == issue.id }.map do |relation|
          i ={}
          i[:id] = relation.other_issue(issue).id
          i[:subject] = relation.other_issue(issue).subject
          blocks << i
        end
        item[:blocked_by_issues] = blocks
      end

      if @query.has_column?(:questionlist) && issue.project.module_enabled?('checklists')
        item[:question_lists] = issue.questionlists.map { |checklist| transform_questionlist_info(checklist) }
      end

      if KanbanQuery.redmineup_tags_installed && @query.has_column?(:tags)
        item[:tags] = format_issue_tags(issue)
      end

      item[:order] = issue.kanban_issue.sort_order
      
      result << item
    end
   
    result
  end

  def format_issue(issue)
    # changesets = issue.changesets.visible.preload(:repository, :user).to_a

    api = {
      assigned_to: issue.assigned_to.nil? ? {} : { id: issue.assigned_to.id, name: issue.assigned_to.name },
      author: { id: issue.author.id, name: user_name_or_anonymous(issue.author) },
      category_id: issue.category_id,
      closed_on: issue.closed_on,
      created_on: issue.created_on,
      description: issue.description,
      done_ratio: issue.done_ratio,
      estimated_hours: issue.estimated_hours,
      fixed_version_id: issue.fixed_version_id,
      is_private: issue.is_private?,
      lock_version: issue.lock_version,
      priority_id: issue.priority_id,
      priority: issue.priority.name,
      project_id: issue.project_id,
      project_name: issue.project.name,
      start_date: issue.start_date,
      subject: issue.subject,
      tracker_id: issue.tracker_id,
      tracker: issue.tracker.name,
      question_lists_can_add: issue.editable?,
      question_lists_can_add_visa: issue.editable?,
      question_lists: issue.questionlists.map { |checklist| transform_questionlist(checklist) },
      spent_hours: issue.spent_hours,
      relations: issue.relations.map do |relation|
          {
            type: l(IssueRelation::TYPES[relation.relation_type][ (relation.issue_from_id == issue.id) ? :name : :sym_name]),
            other_id: (relation.issue_from_id == issue.id) ? relation.issue_to_id : relation.issue_from_id,
            subject: relation.other_issue(issue).subject,
            status: relation.other_issue(issue).status.name,
            assigned_to: relation.other_issue(issue).assigned_to.nil? ? l(:label_user_anonymous) : relation.other_issue(issue).assigned_to.name ,
            is_closed: relation.other_issue(issue).closed?,
          }

      end
    }

    api = api.merge(format_issue_base(issue))

    api[:attacments] = []
    issue.attachments.map do |attachement|
      api[:attacments] << transform_attachment(attachement)
    end

    if !issue.parent_issue_id.nil?
      api = api.merge(format_issue_parent(issue))
    end

    if KanbanQuery.redmineup_tags_installed
      api[:tags] = format_issue_tags(issue)
    end


    journals = issue.visible_journals_with_index
    api[:journals] = []
    journals.each do |journal|
      journal_model = {
        id: journal.id,
        user: journal.user.nil? ? nil : { id: journal.user_id, name: journal.user.name },
        notes: journal.notes,
        created_on: journal.created_on,
        private_notes: journal.private_notes,
        details: []
      }
      journal.visible_details.each do |detail|
        journal_model[:details] << {
          property: detail.property,
          name: detail.prop_key,
          old_value: detail.old_value,
          new_value: detail.value
        }
      end
      api[:journals] << journal_model
    end

    api
  end

  def format_issue_parent(issue)
    {
      :parent_id => issue.parent_issue_id,
      :parent_name => Issue.find_by(:id=> issue.parent_issue_id).nil? ? "" : Issue.find_by(:id=> issue.parent_issue_id).subject
    }
  end

  def format_issue_tags(issue)
    if issue.respond_to?(:tag_list) && issue.respond_to?(:tag_counts) && issue.tag_list.present?
      require 'digest/md5'
      tags = []
      issue.tag_counts.collect do |t|
        i = {}
        i[:name] = t.name
        i[:color] = "##{Digest::MD5.hexdigest(t.name)[0..5]}" if RedmineupTags.settings['issues_use_colors'].to_i > 0
        tags << i
      end
      tags
    end
  end


  def get_current_user
    {
      id: User.current.id,
      name: "#{User.current.firstname} #{User.current.lastname}",
      api_key: User.current.api_token.nil? ? nil : User.current.api_token.value,
      language: locale.to_s,
      group_ids: User.current.group_ids
    }
  end

  def get_checklist_settings
    {
      attachment_max_size: Setting.attachment_max_size.to_i.kilobytes,
      attachment_extensions_denied: Setting.attachment_extensions_denied.strip,
      attachment_extensions_allowed: Setting.attachment_extensions_allowed.strip
    }
  end

  def format_statuses(items, board_statuses)
    data = []
    board_statuses = [] if board_statuses.nil?

    items.each do |item|
      board_status = board_statuses.find { |el| el[:id] == item.id }
      status = {
        id: item.id,
        name: item.name,
        color: Setting.plugin_redmine_kanban["status_color_#{item.id}"],
        is_closed: board_status.nil? ? item.is_closed : board_status[:is_closed],
        position: item.position
      }

        data.insert(item.id, status) 
      end

    data.select { |el| el }.sort_by { |el| el[:position] }
  end

  def kanban_my_issues_link(label, css_class)
    assigned_to_id_filter_values = [User.current.id.to_s]
    User.current.group_ids.each { |group_id| assigned_to_id_filter_values.push(group_id.to_s) }

    url_params = {
      controller: 'kanban',
      action: 'index',
      utf8: '✓',
      set_filter: 1,
      sort: 'id:desc',
      f: %i[status_id assigned_to_id],
      op: { status_id: 'o', assigned_to_id: '=' },
      v: { assigned_to_id: assigned_to_id_filter_values },
      c: %i[project tracker status priority subject assigned_to updated_on cf_1 author spent_hours],
      t: %i[estimated_hours]
    }
    link_to(label, url_params, class: css_class)
  end

  def available_statuses_tags(query)
    tags = ''.html_safe
    query.available_statuses.each do |status|
       tags << content_tag('label', check_box_tag('s[]', status.id, query.has_status?(status.id), :id => status.name.to_s) + " #{status.name.to_s}", :class => 'inline')
    end
    tags
  end
  
  def available_kanban_columns_tags(query)
    # p query.available_columns
    tags = ''.html_safe
    query.available_block_columns.each do |column|
      tags << content_tag('label', check_box_tag('c[]', column.name.to_s, query.has_column?(column), :id => nil) + " #{column.caption}", :class => 'inline')
    end
    tags
  end


  def to_arr(query)
    return {:query_id => query.id } if query.id
    return {:set_filter => "1", :sort => "id:desc",
            "f" => ["status_id",""], "op" =>{"status_id"=>"o"},
            "group_by"=>"",
            "c"=> query.columns.map{|c| c.name},
            "s"=>query.statuses
    }
  end

end
