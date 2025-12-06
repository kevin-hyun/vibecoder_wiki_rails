class CreateUserActivities < ActiveRecord::Migration[7.2]
  def change
    create_table :user_activities, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :activity_type, null: false
      t.string :target_type
      t.uuid :target_id
      t.integer :points_earned, default: 0
      t.jsonb :metadata, default: {}  # PostgreSQL JSONB 타입
      
      t.timestamps null: false
    end
    
    # 인덱스
    add_index :user_activities, :user_id
    add_index :user_activities, :activity_type
    add_index :user_activities, [:target_type, :target_id]
    add_index :user_activities, :created_at
    add_index :user_activities, :points_earned
    
    # PostgreSQL GIN 인덱스 (JSONB 검색용)
    add_index :user_activities, :metadata, using: :gin
    
    # Foreign key
    add_foreign_key :user_activities, :users, primary_key: :id, on_delete: :cascade
    
    # 제약조건
    add_check_constraint :user_activities, 
                        "activity_type IN ('explanation_created', 'vote_cast', 'concept_created', 'best_explanation_selected', 'concept_verified')", 
                        name: "activity_type_check"
  end
end