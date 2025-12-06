class CreateBookmarks < ActiveRecord::Migration[7.2]
  def change
    create_table :bookmarks, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.uuid :concept_id, null: false
      
      t.timestamps null: false
    end
    
    # 인덱스
    add_index :bookmarks, :user_id
    add_index :bookmarks, :concept_id
    add_index :bookmarks, [:user_id, :concept_id], unique: true
    add_index :bookmarks, :created_at
    
    # Foreign keys
    add_foreign_key :bookmarks, :users, primary_key: :id, on_delete: :cascade
    add_foreign_key :bookmarks, :concepts, primary_key: :id, on_delete: :cascade
  end
end