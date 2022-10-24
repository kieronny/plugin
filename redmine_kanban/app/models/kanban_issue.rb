class KanbanIssue < ActiveRecord::Base
  unloadable
  belongs_to :issue
  validates :block_reason, length: { maximum: 1000, too_long: '%{count} characters is the maximum allowed' }, allow_blank: true


  private

end
