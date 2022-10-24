module QuestionHelper
  def transform_question(record)
    {
      editable: record.editable?,
      id: record.id,
      title: record.title,
      done: record.done,
      answer: record.answer,
      answered_at: record.answered_at,
      assigned_to: record.assigned_to.nil? ? nil : record.assigned_to.name,
      answered_by: record.answered_by.nil? ? nil : record.answered_by.name,
      assigned_to_id: record.assigned_to.nil? ? nil : record.assigned_to.id,
      completed_at: record.completed_at,
      completed_by: record.completed_by.nil? ? nil : record.completed_by.name,
      sort_order: record.sort_order,
      updated_at: record.updated_at,
      created_by: user_name_or_anonymous(record.created_by),
      attachments: record.attachments.map { |a| transform_attachment a }
    }
  end

  def transform_template_item(record)
    {
      id: record.id,
      title: record.title,
      assigned_to: record.assigned_to.nil? ? nil : record.assigned_to.name,
      assigned_to_id: record.assigned_to.nil? ? nil : record.assigned_to.id,
      sort_order: record.sort_order,
      updated_at: record.updated_at,
      created_by:user_name_or_anonymous(record.created_by),
      deadline: record.deadline,
    }
  end


  def transform_attachment( attachment)
    {
      id: attachment.id,
      filename: attachment.filename,
      filesize: attachment.filesize,
      author: user_name_or_anonymous(attachment.author),
      created_on: attachment.created_on,
      description: attachment.description,
    }
  end

  def transform_user(record)
    {
      id: record.id,
      name: record.name,
      type: record.type
    }
  end

  def user_or_anonymous(user)
    user.nil? ? User.anonymous : user
  end

  def user_name_or_anonymous(user)
      user.nil? ? l(:label_user_anonymous) : user.name
  end

  def user_name_or_anonymous_by_id(user_id)
    user = Principal.find_by(:id => user_id)
    user_name_or_anonymous(user)
  end

  def shorten_text(text, length = 30)
    return "" if text.nil?
    text.length > length ? text[0,length].to_s+"..." : text
  end

  def types_hash
    { ChecklistBase::TYPE_USUAL.downcase => [], ChecklistBase::TYPE_PERSONAL.downcase => [] }
  end
end
