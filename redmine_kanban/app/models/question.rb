class Question < ChecklistItemBase

  self.table_name = 'kanban_question_item'

  belongs_to :questionlist, :class_name => "Questionlist", :foreign_key => "questionlist_id"
  belongs_to :completed_by, :class_name => "User", :foreign_key => "completed_by_id"
  belongs_to :answered_by, :class_name => "User", :foreign_key => "answered_by_id"

  has_many :attachments, lambda {order("#{Attachment.table_name}.created_on ASC, #{Attachment.table_name}.id ASC")},
           as: :container, dependent: :destroy, inverse_of: :container

  def set_assigned_to(data)
    if data == nil || data.to_i == 0
      self.assigned_to = nil
    else
      user = Principal.find(data.to_i)
      if user.instance_of? User
        Watcher.create(:watchable => self.questionlist.issue, :user => user)
      end
      self.assigned_to = user
    end
  end

  def set_completed(data)
    self.done = data

    if data == true
      self.completed_by = User.current
      self.completed_at = Time.now
    else
      self.completed_by = nil
      self.completed_at = nil
    end
  end

  def set_answer(data)
    self.answer = data
    self.answered_by = User.current
    self.answered_at = Time.now
  end

  def delete_answer
    self.answer = nil
    self.answered_by = nil
    self.answered_at = nil
  end

  def editable?(user=User.current)
    return true if user.admin?
    if questionlist.issue.visible?(user) != true
      return false
    end
   
    user.allowed_to?(:edit_checklists, questionlist.issue.project)
  end

  private

end