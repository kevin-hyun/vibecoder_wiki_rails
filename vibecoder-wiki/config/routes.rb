Rails.application.routes.draw do
  # Devise 인증 라우트
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations'
  }

  # Root 라우트
  root 'concepts#index'

  # 개념 관련 라우트 (중첩된 설명 포함)
  resources :concepts, except: [:destroy] do
    member do
      patch :verify        # 관리자 검증
      post :bookmark      # 북마크 토글
    end
    
    collection do
      get :search         # 검색
      get :suggestions    # 자동완성
      get :popular        # 인기 개념
      get :beginner       # 초보자용 개념
    end

    # 중첩된 설명 라우트
    resources :explanations do
      member do
        patch :vote           # 투표 (도움됨/어려움)
        patch :make_best     # 베스트 설명 선정 (관리자)
      end
    end
  end

  # 사용자 프로필
  resources :users, only: [:show, :edit, :update], param: :id do
    member do
      get :profile
      get :bookmarks
      get :activities
    end
  end

  # UI 컴포넌트 가이드
  get 'ui-components', to: 'ui_components#index'
  get 'ui-components/:component', to: 'ui_components#show', as: :ui_component

  # 관리자 페이지
  namespace :admin do
    root 'dashboard#index'
    
    resources :concepts do
      member do
        patch :verify
        patch :toggle_popular
      end
    end
    
    resources :users do
      member do
        patch :toggle_admin
        patch :toggle_premium
      end
    end
    
    resources :explanations, only: [:index, :show, :destroy] do
      member do
        patch :make_best
        patch :remove_best
      end
    end
    
    resources :votes, only: [:index, :destroy]
    resources :user_activities, only: [:index]
    
    # 통계 및 분석
    get 'analytics', to: 'analytics#index'
    get 'analytics/concepts', to: 'analytics#concepts'
    get 'analytics/users', to: 'analytics#users'
    get 'analytics/votes', to: 'analytics#votes'
  end

  # API 라우트 (향후 모바일 앱용)
  namespace :api do
    namespace :v1 do
      resources :concepts, only: [:index, :show] do
        collection do
          get :search
          get :popular
        end
        
        resources :explanations, only: [:index, :show, :create] do
          member do
            patch :vote
          end
        end
      end
      
      resources :users, only: [:show] do
        member do
          get :profile
          get :activities
        end
      end
    end
  end

  # 정적 페이지
  get 'about', to: 'pages#about'
  get 'privacy', to: 'pages#privacy'
  get 'terms', to: 'pages#terms'
  get 'contact', to: 'pages#contact'

  # 건강체크 (배포용)
  get 'health', to: 'health#check'

  # ActionCable 라우트는 자동 마운트됨 (/cable)
  mount ActionCable.server => '/cable'

  # Sidekiq 모니터링 (관리자만)
  authenticate :user, ->(user) { user.admin? } do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  # 404 처리 (개발용)
  unless Rails.env.production?
    match '*path', to: 'application#render_404', via: :all, constraints: lambda { |req|
      !req.xhr? && req.format.html?
    }
  end
end