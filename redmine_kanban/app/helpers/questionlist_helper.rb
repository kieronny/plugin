module QuestionlistHelper
  include QuestionHelper

  def transform_questionlist(record)
    {
      editable: record.editable?,
      id: record.id,
      title: record.title,
      sort_order: record.sort_order,
      updated_at: record.updated_at,
      created_by: user_name_or_anonymous(record.created_by),
      deleted: record.deleted,
      list_type: record.list_type,
      tasks: record.questions.where(deleted: false).order(sort_order: :asc).map { |question| transform_question(question) }
    }
  end


  def transform_questionlist_info(record)
    res = {}
    res['id'] = record.id
    res['title'] = record.title

    questions_total = 0
    questions_completed = 0
    assignees = []
    record.items.each do |r|
      questions_total += 1
      if r.done
        questions_completed += 1
      end
      unless r.done == true || r.assigned_to == nil || assignees.detect {|f| f['id'] == r.assigned_to.id }
        assignees << transform_user(r.assigned_to)
      end
    end

    res['questions_total'] = questions_total
    res['questions_completed'] = questions_completed
    res['assignees'] = assignees
    res['deleted'] = record.deleted
    res['list_type'] = record.list_type

    res
  end


end
