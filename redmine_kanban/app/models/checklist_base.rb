class ChecklistBase < ActiveRecord::Base
  self.abstract_class = true
  TYPE_USUAL = 'Usual'.freeze
  TYPE_PERSONAL = 'Assigned'.freeze

  include Redmine::SafeAttributes


  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'


  validates_presence_of :title
  validates_length_of :title, maximum: 50

  validates_presence_of :sort_order
  validates_numericality_of :sort_order

  validates_presence_of :list_type



  def set_title(data)
    self.title = data
  end

  def set_deleted(data)
    self.deleted = data
  end

  def set_list_type(list_type)
    self.list_type = list_type
  end


  private



end
