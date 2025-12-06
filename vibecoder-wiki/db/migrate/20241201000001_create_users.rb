class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: :uuid do |t|
      # Devise 기본 필드
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      
      # 비전공자 친화적 필드
      t.string :display_name, null: false
      t.text :photo_url
      t.boolean :is_premium, default: false
      t.datetime :premium_expires_at
      t.string :role, default: 'user'
      t.integer :explanations_count, default: 0
      t.integer :total_votes, default: 0
      t.integer :concepts_contributed, default: 0
      t.string :theme, default: 'system'
      t.boolean :email_notifications, default: true
      
      # OAuth 필드
      t.string :provider
      t.string :uid
      
      # Devise trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      
      # Devise recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      
      # Devise rememberable
      t.datetime :remember_created_at
      
      t.timestamps null: false
    end
    
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, [:provider, :uid],     unique: true
    add_index :users, :display_name
    add_index :users, :role
    add_index :users, :is_premium
  end
end