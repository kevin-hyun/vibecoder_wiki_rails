Create a complete Rails 7.2 knowledge-sharing platform from scratch with ALL models, migrations, and initial setup in ONE response.

PROJECT NAME: devconcepts  
PURPOSE: Developer knowledge sharing platform where users can create concepts, write explanations, and vote

COMPLETE THIS ENTIRE SETUP:

1\. Generate the exact bash commands to create and setup the Rails app:  
\- Rails new command with tailwind and sqlite3  
\- Bundle add commands for all required gems  
\- All rails generate commands needed  
\- Database setup commands

2\. Create the COMPLETE Gemfile with these gems:  
\`\`\`ruby  
source "https://rubygems.org"

\# Core  
gem "rails", "\~\> 7.2.0"  
gem "sprockets-rails"  
gem "sqlite3", "\~\> 1.4"  
gem "puma", "\~\> 6.0"  
gem "bootsnap", require: false  
gem "image\_processing", "\~\> 1.2"

\# Frontend  
gem "importmap-rails"  
gem "turbo-rails"  
gem "stimulus-rails"  
gem "tailwindcss-rails"  
gem "view\_component"

\# Authentication  
gem "devise"  
gem "omniauth"  
gem "omniauth-google-oauth2"  
gem "omniauth-rails\_csrf\_protection"

\# Production Database Optimization  
gem "litestack" \# SQLite for production

\# Features  
gem "pagy" \# Pagination  
gem "friendly\_id" \# SEO URLs  
gem "redis" \# For ActionCable and caching

\# Admin  
gem "blazer" \# Analytics dashboard

group :development, :test do  
  gem "debug"  
  gem "faker"  
  gem "factory\_bot\_rails"  
end

group :development do  
  gem "web-console"  
end

group :production do  
  gem "rack-attack" \# Rate limiting  
  gem "lograge" \# Better logging  
end

3\. Create ALL migration files with this EXACT database structure:  
\# db/migrate/001\_create\_users.rb  
class CreateUsers \< ActiveRecord::Migration\[7.2\]  
  def change  
    create\_table :users, id: :string do |t|  
      \# Devise fields will be added by devise  
      t.string :email, null: false  
      t.string :display\_name, null: false  
      t.string :photo\_url  
      t.boolean :is\_premium, default: false  
      t.datetime :premium\_expires\_at  
      t.string :role, default: 'user' \# guest, user, premium, admin, super\_admin  
        
      \# Stats columns (embedded)  
      t.integer :explanations\_count, default: 0  
      t.integer :total\_votes, default: 0  
      t.integer :views\_count, default: 0    
      t.integer :concepts\_contributed, default: 0  
        
      \# Preferences columns (embedded)  
      t.boolean :email\_notifications, default: true  
      t.string :theme, default: 'system' \# light, dark, system  
        
      t.timestamps  
    end  
      
    add\_index :users, :email, unique: true  
    add\_index :users, :role  
    add\_index :users, \[:is\_premium, :premium\_expires\_at\]  
  end  
end

\# db/migrate/002\_create\_concepts.rb  
class CreateConcepts \< ActiveRecord::Migration\[7.2\]  
  def change  
    create\_table :concepts, id: :string do |t|  
      t.string :title, null: false  
      t.text :description, null: false  
      t.string :category, null: false \# planning, design, development, etc  
      t.string :level, null: false \# beginner, intermediate, advanced  
      t.integer :view\_count, default: 0  
      t.integer :explanation\_count, default: 0  
      t.decimal :average\_rating, precision: 3, scale: 2, default: 0.00  
      t.string :created\_by  
      t.boolean :is\_verified, default: false  
      t.string :slug \# for friendly\_id  
        
      t.timestamps  
    end  
      
    add\_index :concepts, :category  
    add\_index :concepts, :level  
    add\_index :concepts, :created\_by  
    add\_index :concepts, :is\_verified  
    add\_index :concepts, :view\_count  
    add\_index :concepts, :slug, unique: true  
    add\_foreign\_key :concepts, :users, column: :created\_by, primary\_key: :id  
  end  
end

\# Continue with ALL other migration files...

4.Create ALL model files with complete associations and validations:  
\# app/models/user.rb  
class User \< ApplicationRecord  
  devise :database\_authenticatable, :registerable,  
         :recoverable, :rememberable, :validatable,  
         :omniauthable, omniauth\_providers: \[:google\_oauth2\]  
    
  \# Associations  
  has\_many :concepts, foreign\_key: :created\_by, dependent: :nullify  
  has\_many :explanations, foreign\_key: :author\_id, dependent: :destroy  
  has\_many :votes, dependent: :destroy  
  has\_many :activities, class\_name: 'UserActivity', dependent: :destroy  
  has\_many :payments, dependent: :destroy  
    
  \# Validations  
  validates :display\_name, presence: true, length: { minimum: 2, maximum: 50 }  
  validates :role, inclusion: { in: %w\[guest user premium admin super\_admin\] }  
  validates :theme, inclusion: { in: %w\[light dark system\] }  
    
  \# Scopes  
  scope :premium, \-\> { where(is\_premium: true) }  
  scope :admins, \-\> { where(role: \['admin', 'super\_admin'\]) }  
  scope :active\_recently, \-\> { where('last\_sign\_in\_at \> ?', 30.days.ago) }  
    
  \# Callbacks  
  before\_validation :set\_default\_display\_name, on: :create  
    
  \# Methods  
  def premium\_active?  
    is\_premium && premium\_expires\_at&.future?  
  end  
    
  def admin?  
    role.in?(\['admin', 'super\_admin'\])  
  end  
    
  private  
    
  def set\_default\_display\_name  
    self.display\_name ||= email&.split('@')&.first  
  end  
end

\# Continue with ALL other model files...

5.Create complete seeds.rb file:  
\# db/seeds.rb  
require 'faker'

puts "Cleaning database..."  
\[Vote, Explanation, Concept, User\].each(&:destroy\_all)

puts "Creating users..."  
\# Admin user  
admin \= User.create\!(  
  id: SecureRandom.uuid,  
  email: 'admin@devconcepts.com',  
  password: 'password123',  
  display\_name: 'Admin',  
  role: 'admin',  
  is\_premium: true,  
  premium\_expires\_at: 1.year.from\_now  
)

\# Regular users  
20.times do  
  User.create\!(  
    id: SecureRandom.uuid,  
    email: Faker::Internet.unique.email,  
    password: 'password123',  
    display\_name: Faker::Name.name,  
    role: \['user', 'user', 'premium'\].sample,  
    is\_premium: \[true, false\].sample,  
    photo\_url: "https://ui-avatars.com/api/?name=\#{Faker::Name.first\_name}"  
  )  
end

puts "Creating concepts..."  
categories \= %w\[planning design development deployment operation marketing business data frontend backend devops tool\]  
levels \= %w\[beginner intermediate advanced\]

50.times do  
  concept \= Concept.create\!(  
    id: SecureRandom.uuid,  
    title: Faker::ProgrammingLanguage.name \+ " " \+ \["Basics", "Advanced", "Patterns", "Best Practices"\].sample,  
    description: Faker::Lorem.paragraph(sentence\_count: 3),  
    category: categories.sample,  
    level: levels.sample,  
    created\_by: User.pluck(:id).sample,  
    is\_verified: \[true, false\].sample  
  )  
    
  \# Add tags  
  5.times do  
    concept.concept\_tags.create\!(tag: Faker::ProgrammingLanguage.name.downcase)  
  end  
end

\# Continue with explanations, votes, etc...  
6.Create config/database.yml optimized for Litestack:

default: \&default  
  adapter: sqlite3  
  pool: \<%= ENV.fetch("RAILS\_MAX\_THREADS") { 5 } %\>  
  timeout: 5000

development:  
  \<\<: \*default  
  database: storage/development.sqlite3

test:  
  \<\<: \*default  
  database: storage/test.sqlite3

production:  
  \<\<: \*default  
  database: storage/production.sqlite3  
  \# Litestack optimizations  
  journal\_mode: WAL  
  synchronous: NORMAL  
  cache\_size: \-64000  
  busy\_timeout: 10000

7.Create complete Devise setup with Google OAuth:  
\# config/initializers/devise.rb  
8\. Create routes.rb with all routes:  
\# config/routes.rb  
Rails.application.routes.draw do  
  devise\_for :users, controllers: {  
    omniauth\_callbacks: 'users/omniauth\_callbacks'  
  }  
    
  root 'concepts\#index'  
    
  resources :concepts do  
    resources :explanations, only: \[:create, :edit, :update, :destroy\] do  
      member do  
        post :upvote  
        delete :remove\_vote  
      end  
    end  
      
    member do  
      post :verify \# admin only  
    end  
  end  
    
  resources :users, only: \[:show, :edit, :update\] do  
    member do  
      get :explanations  
      get :votes  
    end  
  end  
    
  get 'search', to: 'search\#index'  
    
  namespace :admin do  
    root 'dashboard\#index'  
    resources :concepts, only: \[:index, :edit, :update, :destroy\]  
    resources :users, only: \[:index, :edit, :update\]  
    mount Blazer::Engine, at: "blazer" \# Analytics  
  end  
    
  \# Health check for deployment  
  get 'health', to: proc { \[200, {}, \['OK'\]\] }  
end  
Devise.setup do |config|  
  config.mailer\_sender \= 'noreply@devconcepts.com'  
  require 'devise/orm/active\_record'  
    
  config.case\_insensitive\_keys \= \[:email\]  
  config.strip\_whitespace\_keys \= \[:email\]  
  config.skip\_session\_storage \= \[:http\_auth\]  
  config.stretches \= Rails.env.test? ? 1 : 12  
  config.reconfirmable \= false  
  config.expire\_all\_remember\_me\_on\_sign\_out \= true  
  config.password\_length \= 6..128  
  config.email\_regexp \= /\\A\[^@\\s\]+@\[^@\\s\]+\\z/  
  config.reset\_password\_within \= 6.hours  
  config.sign\_out\_via \= :delete  
    
  \# Google OAuth2  
  config.omniauth :google\_oauth2,  
                  ENV\['GOOGLE\_CLIENT\_ID'\],  
                  ENV\['GOOGLE\_CLIENT\_SECRET'\],  
                  {  
                    scope: 'email,profile',  
                    prompt: 'select\_account',  
                    image\_aspect\_ratio: 'square',  
                    image\_size: 200  
                  }  
end

9.Create ApplicationController with helpers:  
\# app/controllers/application\_controller.rb  
class ApplicationController \< ActionController::Base  
  before\_action :configure\_permitted\_parameters, if: :devise\_controller?  
    
  protected  
    
  def configure\_permitted\_parameters  
    devise\_parameter\_sanitizer.permit(:sign\_up, keys: \[:display\_name\])  
    devise\_parameter\_sanitizer.permit(:account\_update, keys: \[:display\_name, :photo\_url, :theme, :email\_notifications\])  
  end  
    
  def require\_admin\!  
    redirect\_to root\_path, alert: 'Not authorized' unless current\_user&.admin?  
  end  
end  
10.Create .env.example file:  
\# Google OAuth  
GOOGLE\_CLIENT\_ID=your\_client\_id\_here  
GOOGLE\_CLIENT\_SECRET=your\_client\_secret\_here

\# Rails  
RAILS\_MASTER\_KEY=your\_master\_key\_here  
SECRET\_KEY\_BASE=generate\_with\_rails\_secret

\# Database (Production)  
DATABASE\_URL=sqlite3:storage/production.sqlite3

\# Redis (optional for ActionCable)  
REDIS\_URL=redis://localhost:6379/1

OUTPUT ALL OF THESE FILES COMPLETELY:

Exact shell commands to run (in order)  
Complete Gemfile  
ALL migration files (10+ files)  
ALL model files with associations (10+ files)  
Complete seeds.rb with realistic data  
database.yml with Litestack config  
devise.rb initializer  
routes.rb with all routes  
application\_controller.rb  
.env.example

Do NOT use placeholders or "..." \- write EVERYTHING out completely.  
Make sure all foreign keys use string type to match Firebase UIDs.  
Include all join tables for many-to-many relationships.  
Ensure the app can run immediately after following these steps.

