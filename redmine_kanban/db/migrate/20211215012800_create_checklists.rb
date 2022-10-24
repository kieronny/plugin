class CreateChecklists < ActiveRecord::Migration[5.2]
  # require '../../app/models/checklist'

  def change
    create_table Questionlist.table_name do |t|
      t.string :title, :null => false, :limit => 100
      t.datetime :created_at, :null => false
      t.boolean :deleted, :default => false, :null => false
      t.datetime :updated_at, :null => false
      t.integer :sort_order, :default => 0, :null => false
      t.references :issue, :null => true
      t.references :created_by, :null => false
      t.string :list_type, :limit => 20, :default => Questionlist::TYPE_USUAL, :null => false
      t.references :project, :null => true
      t.boolean :is_template, :default => false, :null => false
    end

    create_table Question.table_name do |t|
      t.boolean :done, :default => false, :null => false
      t.string :title, :null => false, :limit => 1000
      t.text :answer, :null => true
      t.datetime :completed_at, :null => true
      t.references :completed_by, :null => true
      t.references :assigned_to, :null => true
      t.references :created_by, :null => false
      t.datetime :created_at, :null => false
      t.datetime :updated_at, :null => false
      t.integer :sort_order, :default => 0, :null => false
      t.references :questionlist, :null => false
      t.boolean :deleted, :default => false, :null => false
    end

    create_table KanbanIssue.table_name do |t|
      t.string :block_reason, :null => true, :limit => 1000
      t.integer :sort_order, :default => 1, :null => false
      t.references :issue, :null => false
      t.datetime :blocked_at, :null=>true
    end
  end
end
