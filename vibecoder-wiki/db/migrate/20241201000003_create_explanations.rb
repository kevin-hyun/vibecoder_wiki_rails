class CreateExplanations < ActiveRecord::Migration[7.2]
  def change
    create_table :explanations, id: :uuid do |t|
      t.uuid :concept_id, null: false
      t.uuid :author_id, null: false
      t.text :content, null: false
      t.text :simple_analogy
      t.text :example
      t.string :difficulty_level, default: 'beginner'
      t.text :tags, array: true, default: []  # PostgreSQL array 타입
      t.integer :vote_count, default: 0
      t.integer :helpfulness_score, default: 0
      t.integer :clarity_score, default: 0
      t.boolean :is_best_explanation, default: false
      t.text :reason
      
      t.timestamps null: false
    end
    
    # 인덱스
    add_index :explanations, :concept_id
    add_index :explanations, :author_id
    add_index :explanations, :difficulty_level
    add_index :explanations, :vote_count
    add_index :explanations, :helpfulness_score
    add_index :explanations, :is_best_explanation
    add_index :explanations, :created_at
    
    # PostgreSQL Full-Text Search 인덱스 (설명 검색용)
    add_index :explanations, "to_tsvector('korean', content || ' ' || coalesce(simple_analogy, '') || ' ' || coalesce(example, ''))", 
              using: :gin, name: 'explanations_search_idx'
    
    # PostgreSQL GIN 인덱스 (태그 배열 검색용)
    add_index :explanations, :tags, using: :gin
    
    # Foreign keys
    add_foreign_key :explanations, :concepts, primary_key: :id
    add_foreign_key :explanations, :users, column: :author_id, primary_key: :id
    
    # 제약조건 (비전공자 친화적)
    add_check_constraint :explanations, "char_length(content) <= 300", name: "content_length_check"
    add_check_constraint :explanations, "difficulty_level IN ('beginner', 'intermediate', 'advanced')", name: "difficulty_level_check"
  end
end