# 바이브코더 위키 PRD (Product Requirements Document)

## 1. Executive Summary

### Product Name

바이브코더 위키 (VibeCoder Wiki)

### Product Vision

바이브 코딩 입문자가 IT 개념을 가장 쉽게 이해할 수 있는 집단지성 기반 학습 플랫폼

### Target Launch Date

MVP: 2025년 9월 12일 (3일 개발)

### Success Criteria

- DAU 1,000명 달성 (3개월 내)
- 프리미엄 전환율 3% 달성
- 평균 세션 시간 5분 이상

## 2. User Stories & Acceptance Criteria

### 2.1 개념 학습자 (Primary User)

#### US-001: 개념 검색 및 열람

```
As a 바이브 코딩 입문자
I want to 모르는 IT 개념을 검색하고 쉬운 설명을 볼 수 있다
So that 개념을 빠르게 이해하고 개발을 진행할 수 있다

Acceptance Criteria:
- [ ] 메인 페이지에서 검색바를 통해 개념 검색 가능
- [ ] 자동완성 기능으로 관련 개념 추천
- [ ] 키워드 제안 기능으로 연관 검색어 제공
- [ ] 검색 결과는 관련도순으로 정렬
- [ ] 개념 클릭 시 상세 페이지로 이동
```

#### US-002: 설명 열람

```
As a 바이브 코딩 입문자
I want to 한 개념에 대한 여러 설명을 투표순으로 볼 수 있다
So that 나에게 가장 이해하기 쉬운 설명을 찾을 수 있다

Acceptance Criteria:
- [ ] 캐러셀 UI로 베스트 설명 3개 우선 표시
- [ ] 스와이프/클릭으로 다음 설명 확인
- [ ] "더보기" 클릭 시 전체 설명 리스트 표시
- [ ] 각 설명에 투표수, 작성자, 작성일 표시
```

### 2.2 설명 작성자 (Secondary User)

#### US-003: 설명 작성

```
As a IT 개념을 이해한 사용자
I want to 내가 이해한 방식으로 개념을 설명할 수 있다
So that 다른 입문자들을 도울 수 있고 인정받을 수 있다

Acceptance Criteria:
- [ ] 로그인한 사용자만 설명 작성 가능
- [ ] 300자 이내로 설명 작성
- [ ] 태그 3개까지 선택 가능
- [ ] 미리보기 후 등록
- [ ] 등록 즉시 설명 목록에 표시
```

#### US-004: 투표 참여

```
As a 설명을 읽은 사용자
I want to 도움이 된 설명에 투표할 수 있다
So that 좋은 설명이 상위에 노출되도록 기여할 수 있다

Acceptance Criteria:
- [ ] 로그인 없이도 투표 가능 (IP 기반 중복 방지)
- [ ] 👍/👎 버튼으로 간단히 투표
- [ ] 투표 시 실시간으로 숫자 업데이트
- [ ] 이미 투표한 설명은 버튼 비활성화
```

### 2.3 프리미엄 사용자

#### US-005: 프리미엄 가입

```
As a 활발한 사용자
I want to 프리미엄 멤버십을 구독할 수 있다
So that 특별한 기능과 인증서를 받을 수 있다

Acceptance Criteria:
- [ ] 프로필 페이지에서 프리미엄 가입 버튼
- [ ] 월 9,900원 결제 (카드/계좌이체)
- [ ] 결제 완료 즉시 프리미엄 기능 활성화
- [ ] 프로필에 프리미엄 뱃지 표시
```

### 2.4 관리자

#### US-006: 콘텐츠 관리

```
As a 서비스 관리자
I want to 부적절한 설명을 관리하고 개념을 추가/수정할 수 있다
So that 서비스 품질을 유지할 수 있다

Acceptance Criteria:
- [ ] /admin 경로 접근 시 권한 체크
- [ ] 신고된 설명 목록 확인 및 삭제
- [ ] 개념 추가/수정/삭제 기능
- [ ] 모든 관리 활동 로그 기록
```

## 3. Functional Requirements

### 3.1 Authentication & Authorization

#### FR-001: Google OAuth 로그인

```typescript
// Implementation Requirements
- Firebase Auth 사용
- Google Provider만 지원 (MVP)
- 신규 가입 시 자동으로 users 컬렉션에 프로필 생성
- JWT 토큰 기반 세션 관리
```

#### FR-002: 권한 관리

```typescript
// User Roles
enum UserRole {
  GUEST = "guest", // 비로그인 (읽기, 투표만 가능)
  USER = "user", // 일반 사용자
  PREMIUM = "premium", // 프리미엄 사용자
  ADMIN = "admin", // 관리자
  SUPER_ADMIN = "super_admin", // 최고 관리자
}

// Permissions Matrix
const permissions = {
  guest: ["read", "vote"],
  user: ["read", "vote", "write_explanation"],
  premium: ["read", "vote", "write_explanation", "premium_features"],
  admin: ["all_user_permissions", "manage_content", "view_logs"],
  super_admin: ["all_permissions"],
};
```

### 3.2 Core Features

#### FR-003: 개념(Concept) 관리

```ruby
# Rails Routes (config/routes.rb)
resources :concepts do
  member do
    post :verify # 관리자 검증
    post :bookmark # 북마크
  end
  
  collection do
    get :search # 검색
    get :suggestions # 키워드 제안
    get :popular # 인기 개념
    get :beginner # 초보자용 개념
  end
end

# Controller Actions
# GET    /concepts              # 전체 목록
# GET    /concepts/:id          # 상세 정보
# POST   /concepts              # 관리자만 생성
# PATCH  /concepts/:id          # 관리자만 수정
# DELETE /concepts/:id          # 관리자만 삭제
```

#### FR-004: 설명(Explanation) 관리

```ruby
# Rails Nested Routes
resources :concepts do
  resources :explanations, except: [:index, :show] do
    member do
      post :helpful_vote    # 도움됨 투표
      post :difficult_vote  # 어려워요 투표
      delete :remove_vote   # 투표 취소
      post :mark_as_best   # 베스트 설명 선정 (관리자)
    end
  end
end

# Controller Actions
# POST   /concepts/:concept_id/explanations        # 설명 작성
# PATCH  /concepts/:concept_id/explanations/:id   # 작성자만 수정
# DELETE /concepts/:concept_id/explanations/:id   # 작성자/관리자 삭제
```

#### FR-005: UI 컴포넌트 가이드

```ruby
# Rails Static Page (app/controllers/ui_components_controller.rb)
class UiComponentsController < ApplicationController
  def index
    @ui_components = {
      basic: ['button', 'input', 'checkbox', 'radio'],
      layout: ['header', 'footer', 'sidebar', 'grid'], 
      complex: ['modal', 'dropdown', 'tabs', 'accordion']
    }
    
    @interactive_mode = params[:mode] != 'documentation'
  end
end

# Route
get 'ui-components', to: 'ui_components#index'

# ViewComponent 활용
class UiComponentShowcaseComponent < ViewComponent::Base
  def initialize(component_type:, interactive: true)
    @component_type = component_type
    @interactive = interactive
  end
end
```

### 3.3 Premium Features

#### FR-006: 결제 시스템 (바이브 마스터)

```ruby
# Rails Payment Flow with Stripe
class PaymentsController < ApplicationController
  def create_subscription
    # 1. 사용자가 바이브 마스터 가입 클릭
    # 2. Stripe 결제 처리
    # 3. 결제 성공 시 user.update(is_premium: true)
    # 4. premium_expires_at 설정 (30일 후)
    
    current_user.activate_premium!
    redirect_to profile_path, notice: "바이브 마스터가 되신 걸 축하해요!"
  end
end

# User 모델에서
def activate_premium!
  update!(
    is_premium: true,
    premium_expires_at: 1.month.from_now
  )
end

# 일일 배치 작업 (config/schedule.rb - whenever gem)
every 1.day, at: '6:00 am' do
  runner "User.check_premium_expiration!"
end
```

#### FR-007: 인증서 발급

```typescript
// Certificate Generation
GET /api/certificates/generate
Response: {
  certificateId: string,
  pdfUrl: string,
  verificationUrl: string,
  issuedAt: timestamp
}
```

### 3.4 Admin Features

#### FR-008: 관리자 대시보드

```typescript
// Dashboard Metrics
GET /api/admin/metrics
Response: {
  dau: number,
  mau: number,
  newUsersToday: number,
  totalExplanations: number,
  premiumUsers: number,
  revenue: {
    daily: number,
    monthly: number
  }
}
```

#### FR-009: 로그 시스템

```typescript
// Error Logging
interface ErrorLog {
  timestamp: Date;
  level: 'error' | 'warn' | 'info';
  message: string;
  stack?: string;
  context: {
    userId?: string;
    url: string;
    userAgent: string;
  }
}

// Log Storage
Development: ./logs/error-{date}.log
Production: Firestore errorLogs collection
```

#### FR-010: 광고 시스템

```typescript
// Smart Progressive Ad Display
interface AdConfig {
  getAdCount(pageViews: number): number {
    if (pageViews <= 2) return 1;
    if (pageViews <= 5) return 2;
    if (pageViews <= 10) return 2.5;
    return 3;
  }
  
  positions: ['after-carousel', 'bottom', 'sidebar'];
  
  // Premium users see no ads
  shouldShowAd(user: User): boolean {
    return !user.isPremium;
  }
}

// Revenue Sharing (Future)
interface InfluencerRevenue {
  premiumCommission: 0.3; // 30% of premium revenue
  adRevenue?: 0.2;       // 20% of ad revenue (if applicable)
}
```

## 4. Technical Specifications

### 4.1 Tech Stack

```yaml
Backend:
  - Framework: Ruby on Rails 7.2
  - Language: Ruby 3.2+
  - Database: SQLite3 (Litestack 최적화)
  - Authentication: Devise + Google OAuth
  - Template Engine: ERB
  - Background Jobs: Sidekiq (Redis)

Frontend:
  - Styling: Tailwind CSS
  - JavaScript: Stimulus + Turbo
  - Components: ViewComponent
  - Icons: Heroicons
  - Carousel: Swiper.js

DevOps:
  - Hosting: Railway / Heroku
  - Database: SQLite3 (Production)
  - Caching: Redis
  - Monitoring: Rails 내장 로깅 + Custom 분석
  - CI/CD: GitHub Actions
```

### 4.2 Database Schema

#### Rails ActiveRecord Models Structure

```ruby
# Rails ActiveRecord 모델 구조 (SQLite3 기반)
class User < ApplicationRecord
  # Authentication (Devise)
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]
         
  # 비전공자 친화적 필드
  # display_name, email, photo_url, is_premium, premium_expires_at
  # role, explanations_count, total_votes, concepts_contributed
  # email_notifications, theme
end

class Concept < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: :created_by
  has_many :explanations, dependent: :destroy
  has_many :concept_tags, dependent: :destroy
  
  # 비전공자를 위한 필드
  # title, simple_definition, description, category, level
  # why_important, is_verified, is_popular, view_count
end

class Explanation < ApplicationRecord  
  belongs_to :concept
  belongs_to :author, class_name: 'User', foreign_key: :author_id
  has_many :votes, dependent: :destroy
  
  # 쉬운 설명을 위한 필드
  # content(300자 제한), simple_analogy, example
  # difficulty_level, helpfulness_score, clarity_score
  # is_best_explanation, tags
end

class Vote < ApplicationRecord
  belongs_to :user, optional: true # 비로그인 투표 허용
  belongs_to :explanation
  
  # 비전공자 친화적 투표
  # vote_type: 'helpful' or 'difficult' 
  # reason, ip_address (비로그인 사용자용)
end
```

### 4.3 API Response Format

```ruby
# Rails API 응답 형식 (JSON)
# Success Response
{
  success: true,
  data: serialized_data,
  message: "요청이 성공적으로 처리되었습니다"
}

# Error Response  
{
  success: false,
  error: {
    code: "ERR_CODE",
    message: "비전공자 친화적 오류 메시지",
    details: validation_errors
  }
}

# Rails 표준 응답 (HTML 요청시)
# redirect_to concepts_path, notice: "설명이 성공적으로 등록되었어요!"
# redirect_to root_path, alert: "로그인이 필요한 기능이에요."
```

### 4.4 Performance Requirements

- First Contentful Paint: < 1.5s
- Time to Interactive: < 3s
- API Response Time: < 500ms (p95)
- Lighthouse Score: > 90

## 5. UI/UX Specifications

### 5.1 Design System

```scss
// Color Palette
$primary: #6366f1; // Indigo
$secondary: #ec4899; // Pink
$success: #10b981; // Green
$warning: #f59e0b; // Amber
$error: #ef4444; // Red

// Typography
$font-family: "Pretendard", -apple-system, BlinkMacSystemFont;
$font-sizes: (
  xs: 0.75rem,
  sm: 0.875rem,
  base: 1rem,
  lg: 1.125rem,
  xl: 1.25rem,
  2xl: 1.5rem,
  3xl: 1.875rem,
);

// Spacing
$spacing-unit: 0.25rem;
```

### 5.2 Responsive Breakpoints

```scss
// Mobile First
sm: 640px   // Mobile landscape
md: 768px   // Tablet
lg: 1024px  // Desktop
xl: 1280px  // Large desktop
```

### 5.3 Component Library

- Base: Tailwind UI components
- Custom: Explanation cards, Vote buttons, Premium badges
- Third-party: Swiper.js (carousel), React Hot Toast (notifications)

## 6. Security Requirements

### 6.1 Authentication

- OAuth 2.0 via Google
- Session timeout: 30 days
- Refresh token rotation

### 6.2 Authorization

- Role-based access control (RBAC)
- Firebase Security Rules for Firestore
- API route middleware for admin endpoints

### 6.3 Data Protection

- HTTPS only
- Input sanitization (XSS prevention)
- Rate limiting (100 requests/minute per IP)

## 7. Testing Strategy

### 7.1 Unit Tests

```typescript
// Jest + React Testing Library
- Components: 80% coverage
- Utils: 100% coverage
- API routes: 90% coverage
```

### 7.2 Integration Tests

```typescript
// Cypress
- User flows: Login → Search → Vote
- Admin flows: Login → Manage content
- Payment flow (manual testing for MVP)
```

### 7.3 Performance Tests

```typescript
// Lighthouse CI
- Run on every PR
- Block merge if score < 80
```

## 8. Deployment Strategy

### 8.1 Environments (Rails)

```yaml
Development:
  - URL: localhost:3000
  - Database: SQLite3 (storage/development.sqlite3)
  - Auth: Devise + Google OAuth (development keys)

Staging:
  - URL: staging-vibecoder-wiki.railway.app
  - Database: SQLite3 (Litestack optimized)
  - Auth: Devise + Google OAuth (staging keys)

Production:
  - URL: vibecoder-wiki.com
  - Database: SQLite3 (Litestack production)
  - Auth: Devise + Google OAuth (production keys)
```

### 8.2 CI/CD Pipeline (Rails)

#### MVP (3일 개발):
```yaml
# Railway/Heroku 자동 배포
1. Push to main branch
2. Railway/Heroku automatic build & deploy
3. Manual checks locally:
   - bundle exec rspec (테스트)
   - bundle exec rubocop (코드 스타일)
   - rails db:migrate (마이그레이션 확인)
```

#### Post-MVP (팀 확장시):
```yaml
# GitHub Actions 도입
1. Push to main branch
2. Run tests (RSpec, Rubocop, Rails 모델 테스트)
3. Build Rails app with assets precompile
4. Deploy to Railway/Heroku
5. Run database migrations
6. Health check endpoint 확인
7. Slack 알림
```

## 9. Monitoring & Analytics

### 9.1 Application Monitoring

- Custom error logging to Firestore
- Vercel Analytics for performance
- Google Analytics for user behavior

### 9.2 Business Metrics

```typescript
// Daily Reports
- New users
- Active users (DAU/MAU)
- Explanations created
- Votes cast
- Premium conversions
- Revenue
```

## 10. Launch Checklist

### Pre-Launch (Day 3)

- [ ] All core features implemented
- [ ] Mobile responsive design verified
- [ ] SEO meta tags configured
- [ ] Google Analytics installed
- [ ] Error logging tested
- [ ] Admin account created
- [ ] Initial content seeded (20+ concepts)

### Launch Day

- [ ] Domain connected
- [ ] SSL certificate active
- [ ] Firestore indexes created
- [ ] Security rules deployed
- [ ] Monitoring dashboard ready
- [ ] Social media announcement prepared

### Post-Launch (Week 1)

- [ ] User feedback collection
- [ ] Performance optimization
- [ ] Bug fixes from early users
- [ ] Premium features development start

## 11. Risk Mitigation

### Technical Risks

| Risk                     | Probability | Impact | Mitigation                            |
| ------------------------ | ----------- | ------ | ------------------------------------- |
| Firestore quota exceeded | Medium      | High   | Implement caching, optimize queries   |
| Spam explanations        | High        | Medium | Rate limiting, admin moderation       |
| Payment failures         | Low         | High   | Multiple payment methods, retry logic |

### Business Risks

| Risk                   | Probability | Impact | Mitigation                          |
| ---------------------- | ----------- | ------ | ----------------------------------- |
| Low user adoption      | Medium      | High   | SEO optimization, content marketing |
| Low premium conversion | Medium      | Medium | Free trial, better value props      |
| Content quality issues | Medium      | Medium | Community voting, admin curation    |

## 12. Success Metrics (KPIs)

### Week 1

- 100+ registered users
- 50+ explanations created
- 500+ votes cast

### Month 1

- 1,000+ registered users
- 500+ explanations
- 10+ premium subscribers
- 300,000원+ MRR

### Month 3

- 10,000+ registered users
- 2,000+ explanations
- 300+ premium subscribers
- 3,000,000원+ MRR

---

## Appendix A: Rails Routes 및 API Endpoints

### Public Routes (비로그인 접근 가능)

```ruby
# Rails RESTful Routes
GET    /concepts                    # 전체 개념 목록
GET    /concepts/:id               # 개념 상세 (비전공자 친화적)
GET    /concepts/search            # 검색 기능
GET    /concepts/suggestions       # 키워드 제안
GET    /concepts/popular           # 인기 개념 (⭐ 초급 우선)
GET    /concepts/beginner          # 초보자용 개념만

# 설명 관련 (nested routes)
GET    /concepts/:concept_id/explanations    # 개념별 설명 목록
POST   /concepts/:concept_id/explanations/:id/helpful_vote    # 도움됨 투표 (비로그인 가능)
POST   /concepts/:concept_id/explanations/:id/difficult_vote  # 어려워요 투표
```

### Authenticated Endpoints (로그인 필요)

```ruby
# 설명 작성/수정 (본인만)
POST   /concepts/:concept_id/explanations           # 설명 작성
PATCH  /concepts/:concept_id/explanations/:id      # 설명 수정 (작성자만)
DELETE /concepts/:concept_id/explanations/:id      # 설명 삭제 (작성자만)

# 사용자 관련
GET    /users/:id                  # 프로필 페이지
GET    /users/:id/explanations     # 내가 쓴 설명 목록
PATCH  /users/:id                  # 프로필 수정 (본인만)
POST   /concepts/:id/bookmark      # 북마크 추가
DELETE /concepts/:id/unbookmark    # 북마크 제거
```

### Admin Endpoints (관리자만)

```ruby
# 관리자 대시보드
GET    /admin                      # 대시보드
GET    /admin/concepts             # 개념 관리
GET    /admin/users                # 사용자 관리
GET    /admin/explanations         # 설명 관리

# 개념 관리
POST   /concepts                   # 개념 생성 (관리자만)
PATCH  /concepts/:id               # 개념 수정 (관리자만)
DELETE /concepts/:id               # 개념 삭제 (관리자만)
POST   /concepts/:id/verify        # 개념 검증 (관리자만)

# 설명 관리  
POST   /concepts/:concept_id/explanations/:id/mark_as_best    # 베스트 설명 선정
DELETE /admin/explanations/:id                              # 부적절한 설명 삭제
```

## Appendix B: Error Codes

```typescript
enum ErrorCode {
  // Auth Errors (1xxx)
  UNAUTHORIZED = "ERR_1001",
  INVALID_TOKEN = "ERR_1002",

  // Validation Errors (2xxx)
  INVALID_INPUT = "ERR_2001",
  MISSING_REQUIRED = "ERR_2002",

  // Database Errors (3xxx)
  NOT_FOUND = "ERR_3001",
  DUPLICATE_ENTRY = "ERR_3002",

  // Business Logic Errors (4xxx)
  VOTE_LIMIT_EXCEEDED = "ERR_4001",
  CONTENT_TOO_LONG = "ERR_4002",

  // System Errors (5xxx)
  INTERNAL_ERROR = "ERR_5001",
  SERVICE_UNAVAILABLE = "ERR_5002",
}
```
