class CreateConceptViews < ActiveRecord::Migration[7.2]
  def change
    create_table :concept_views, id: :uuid do |t|
      t.uuid :concept_id, null: false
      t.uuid :user_id  # nullable - 비로그인 사용자 허용
      t.string :ip_address, null: false
      t.datetime :viewed_at, null: false
      
      t.timestamps null: false
    end
    
    # 인덱스
    add_index :concept_views, :concept_id
    add_index :concept_views, :user_id
    add_index :concept_views, :ip_address
    add_index :concept_views, :viewed_at
    add_index :concept_views, :created_at
    
    # 복합 인덱스 (중복 조회 체크용)
    add_index :concept_views, [:concept_id, :user_id, :created_at], where: "user_id IS NOT NULL"
    add_index :concept_views, [:concept_id, :ip_address, :created_at], where: "user_id IS NULL"
    
    # Foreign keys
    add_foreign_key :concept_views, :concepts, primary_key: :id, on_delete: :cascade
    add_foreign_key :concept_views, :users, primary_key: :id, on_delete: :nullify
  end
end