class AddAnsweredToQuestion < ActiveRecord::Migration[5.2]
  def change
    add_column Question.table_name, :answered_by_id, :integer
    add_column Question.table_name, :answered_at, :datetime
  end
end
