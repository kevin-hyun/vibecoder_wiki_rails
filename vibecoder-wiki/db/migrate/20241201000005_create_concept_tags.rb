class CreateConceptTags < ActiveRecord::Migration[7.2]
  def change
    create_table :concept_tags, id: :uuid do |t|
      t.uuid :concept_id, null: false
      t.string :tag, null: false
      
      t.timestamps null: false
    end
    
    # 인덱스
    add_index :concept_tags, :concept_id
    add_index :concept_tags, :tag
    add_index :concept_tags, [:concept_id, :tag], unique: true
    
    # PostgreSQL GIN 인덱스 (태그 검색 최적화)
    add_index :concept_tags, :tag, using: :gin, opclass: :gin_trgm_ops
    
    # Foreign key
    add_foreign_key :concept_tags, :concepts, primary_key: :id, on_delete: :cascade
  end
end