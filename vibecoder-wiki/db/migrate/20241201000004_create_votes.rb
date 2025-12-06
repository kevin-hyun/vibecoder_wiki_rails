class CreateVotes < ActiveRecord::Migration[7.2]
  def change
    create_table :votes, id: :uuid do |t|
      t.uuid :user_id  # nullable - 비로그인 사용자 허용
      t.uuid :explanation_id, null: false
      t.string :vote_type, null: false  # 'helpful' or 'difficult'
      t.text :reason
      t.string :ip_address  # 비로그인 사용자 식별용
      
      t.timestamps null: false
    end
    
    # 인덱스
    add_index :votes, :explanation_id
    add_index :votes, :user_id
    add_index :votes, :vote_type
    add_index :votes, :ip_address
    add_index :votes, :created_at
    
    # 복합 인덱스 (중복 투표 방지용)
    add_index :votes, [:user_id, :explanation_id], unique: true, where: "user_id IS NOT NULL"
    add_index :votes, [:ip_address, :explanation_id], unique: true, where: "user_id IS NULL AND ip_address IS NOT NULL"
    
    # Foreign keys
    add_foreign_key :votes, :explanations, primary_key: :id
    add_foreign_key :votes, :users, primary_key: :id, on_delete: :nullify
    
    # 제약조건
    add_check_constraint :votes, "vote_type IN ('helpful', 'difficult')", name: "vote_type_check"
    add_check_constraint :votes, "(user_id IS NOT NULL) OR (ip_address IS NOT NULL)", name: "voter_identification_check"
  end
end