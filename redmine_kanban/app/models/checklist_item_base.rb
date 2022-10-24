class ChecklistItemBase < ActiveRecord::Base
  self.abstract_class = true
  include Redmine::SafeAttributes
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by_id"
  belongs_to :assigned_to, :class_name => "Principal", :foreign_key => "assigned_to_id"

  validates_presence_of :title
  validates_length_of :title, maximum: 1000

  validates_presence_of :sort_order
  validates_numericality_of :sort_order

  def set_order(data)
    old = Question.where(questionlist: self.questionlist, sort_order: data).first
    unless old == nil
      old.sort_order = self.sort_order
      old.save(touch: false)
    end
    self.sort_order = data
  end

  def set_title(data)
    self.title = data
  end

  def set_deleted(data)
    self.deleted = data
  end

end