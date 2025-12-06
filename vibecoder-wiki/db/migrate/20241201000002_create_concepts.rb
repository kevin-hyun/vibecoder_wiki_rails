class CreateConcepts < ActiveRecord::Migration[7.2]
  def change
    create_table :concepts, id: :uuid do |t|
      t.string :title, null: false
      t.text :simple_definition, null: false
      t.text :description
      t.string :category, null: false
      t.integer :level, default: 1
      t.text :why_important
      t.boolean :is_verified, default: false
      t.boolean :is_popular, default: false
      t.integer :view_count, default: 0
      t.decimal :average_rating, precision: 3, scale: 2, default: 0.0
      t.string :slug, null: false
      t.uuid :created_by, null: false
      
      t.timestamps null: false
    end
    
    # PostgreSQL 전용 인덱스
    add_index :concepts, :slug, unique: true
    add_index :concepts, :title, unique: true
    add_index :concepts, :category
    add_index :concepts, :level
    add_index :concepts, :is_verified
    add_index :concepts, :is_popular
    add_index :concepts, :view_count
    add_index :concepts, :created_by
    add_index :concepts, :created_at
    
    # PostgreSQL Full-Text Search 인덱스 (비전공자 친화적 검색)
    add_index :concepts, "to_tsvector('korean', title || ' ' || simple_definition || ' ' || coalesce(description, ''))", 
              using: :gin, name: 'concepts_search_idx'
    
    # Foreign key
    add_foreign_key :concepts, :users, column: :created_by, primary_key: :id
  end
end