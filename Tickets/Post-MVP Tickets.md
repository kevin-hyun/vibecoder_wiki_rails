# Post-MVP Tickets (Week 1-2)

## TICKET-026: Premium Payment Integration

**Priority**: P1 | **Estimate**: 8h | **Status**: Backlog

```
Description:
프리미엄 결제 시스템 구현

Acceptance Criteria:
- [ ] PG사 연동 (토스페이먼츠/아임포트)
- [ ] 결제 플로우 구현
- [ ] 구독 관리 시스템
- [ ] 결제 내역 관리
- [ ] 자동 갱신/취소 처리
- [ ] 환불 처리
- [ ] 광고 제거 기능 자동 적용

Dependencies: User system complete

Premium Benefits:
- 광고 완전 제거
- 프리미엄 배지
- 프로필 커스터마이징
- 공식 인증서 발급
- 고급 통계 대시보드

Technical Notes:
- Webhook for payment status
- Store payment history in Firestore
- Implement retry logic for failed payments
- Auto-apply noAds flag on payment success
```

## TICKET-027: Certificate System

**Priority**: P2 | **Estimate**: 6h | **Status**: Backlog

```
Description:
인증서 발급 시스템

Acceptance Criteria:
- [ ] PDF 인증서 생성
- [ ] 고유 인증 번호 발급
- [ ] 검증 페이지 구현
- [ ] LinkedIn 공유 기능
- [ ] QR 코드 생성
- [ ] 인증서 다운로드 기록

Dependencies: TICKET-026

Components:
- /app/certificates/[id]/page.tsx
- /api/certificates/generate
- PDF template design
```

## TICKET-028: Advanced Admin Features

**Priority**: P2 | **Estimate**: 6h | **Status**: Backlog

```
Description:
고급 관리자 기능

Acceptance Criteria:
- [ ] 사용자 관리 (정지/복구)
- [ ] 상세 통계 대시보드
- [ ] 신고 시스템
- [ ] 벌크 작업 기능
- [ ] 데이터 내보내기 (CSV)
- [ ] 백업 관리

Dependencies: TICKET-018

Features:
- User search and filter
- Batch operations
- Report management queue
- Analytics dashboard
```

## TICKET-029: Gamification Badges

**Priority**: P3 | **Estimate**: 4h | **Status**: Backlog

```
Description:
뱃지 및 레벨 시스템

Acceptance Criteria:
- [ ] 뱃지 종류 정의
- [ ] 획득 조건 구현
- [ ] 프로필 표시
- [ ] 알림 시스템
- [ ] 진행률 표시
- [ ] 뱃지 디자인

Dependencies: User profile system

Badge Types:
- First Explanation
- Popular Explainer (100+ votes)
- Concept Master (10+ explanations)
- Daily Contributor
- Premium Member
```

## TICKET-030: AI Content Moderation

**Priority**: P3 | **Estimate**: 4h | **Status**: Backlog

```
Description:
AI 기반 콘텐츠 검토

Acceptance Criteria:
- [ ] 부적절한 내용 자동 감지
- [ ] 중복 설명 체크
- [ ] 품질 점수 시스템
- [ ] Claude API 연동
- [ ] 자동 플래깅 시스템
- [ ] 관리자 리뷰 큐

Dependencies: Explanation system

API Integration:
- Claude API for content review
- Similarity check algorithm
- Auto-moderation rules
```

# TICKET-031: Influencer Referral System

**Priority**: P2 | **Estimate**: 10h | **Status**: Backlog

```
Description:
인플루언서 추천인 시스템 구현

Acceptance Criteria:
- [ ] 추천 링크 생성 시스템 (?ref=influencer_id)
- [ ] 추천인 추적 (가입 시 referrer 저장)
- [ ] 인플루언서 대시보드
- [ ] 수익 분배 시스템 (프리미엄 구독료 30%)
- [ ] 티어 시스템 구현 (브론즈/실버/골드)
- [ ] 월간 정산 및 리포트

Dependencies: TICKET-026 (Payment system)

Data Structure:
interface ReferralTracking {
  userId: string;
  referrerId: string;
  referralDate: Timestamp;
  conversionDate?: Timestamp;
  isPremium: boolean;
}

interface InfluencerStats {
  influencerId: string;
  totalReferrals: number;
  activeStudents: number;
  premiumConversions: number;
  monthlyRevenue: number;
  tier: 'bronze' | 'silver' | 'gold';
}

Tier System:
- Bronze: 10-49 active students (30% commission)
- Silver: 50-199 active students (35% commission)
- Gold: 200+ active students (40% commission)

Technical Notes:
- Cookie-based tracking for 30 days
- Real-time dashboard updates
- Monthly batch job for commission calculation
- Automated tier updates
```

# TICKET-032: Learning Roadmap Feature

**Priority**: P2 | **Estimate**: 8h | **Status**: Post-MVP

```
Description:
바이브코더 개발 여정에 맞춘 학습 로드맵 기능 구현

Acceptance Criteria:
- [ ] 7단계 개발 여정 UI 구현 (기획→디자인→프론트→백엔드→배포→수익화→운영)
- [ ] 각 단계별 필수/선택 개념 매핑
- [ ] 현재 단계 하이라이트 기능
- [ ] 진도 체크 시스템
- [ ] 프리미엄 사용자 추가 기능 (전체 개념 접근, 진도 자동 저장)
- [ ] 반응형 로드맵 디자인

Dependencies: Core wiki features, Premium system

Data Structure:
interface RoadmapStage {
  id: string;
  name: string; // "기획", "프론트엔드" 등
  order: number;
  requiredConcepts: string[]; // 필수 개념 ID 배열
  optionalConcepts: string[]; // 선택 개념 ID 배열
  description: string;
}

interface UserProgress {
  userId: string;
  currentStage: string;
  completedConcepts: string[]; // 완료한 개념 ID들
  stageProgress: {
    [stageId: string]: {
      completed: number;
      total: number;
      percentage: number;
    }
  };
  lastUpdated: Timestamp;
}

Stage Breakdown:
1. 기획 (Planning)
   - 필수: MVP, 애자일, 사용자스토리
   - 선택: IR, Series A/B, 인큐베이팅

2. 디자인 (Design)
   - 필수: UI/UX, 컴포넌트, 와이어프레임
   - 선택: 피그마, 디자인시스템

3. 프론트엔드 (Frontend)
   - 필수: HTML/CSS, JavaScript, React/Vue
   - 선택: TypeScript, 상태관리, 빌드도구

4. 백엔드 (Backend)
   - 필수: API, 데이터베이스, 서버
   - 선택: 인증, 캐싱, 로드밸런서

5. 배포 (Deployment)
   - 필수: 도메인, 호스팅, CI/CD
   - 선택: 도커, 쿠버네티스, 모니터링

6. 수익화 (Monetization)
   - 필수: 비즈니스모델, 결제시스템
   - 선택: 광고, 구독, B2B

7. 운영 (Operations)
   - 필수: 애널리틱스, 유지보수
   - 선택: A/B테스트, 그로스해킹

Free vs Premium:
무료 사용자:
- 전체 로드맵 구조 보기
- 각 단계당 필수 개념 3개
- 수동 진도 체크

프리미엄 사용자:
- 모든 개념 (필수 + 선택)
- 진도 자동 저장
- 완료율 표시 및 통계
- 단계 완료 애니메이션

Technical Notes:
- 로드맵 데이터는 별도 컬렉션으로 관리
- 진도는 localStorage (무료) / Firestore (프리미엄)
- 시각적으로 매력적인 progress bar 디자인
- 모바일에서는 세로 스크롤 형태로 변환

UI/UX Considerations:
- 전체 여정을 한눈에 볼 수 있는 시각화
- 현재 위치 명확한 표시
- 각 단계 클릭 시 smooth scroll to concepts
- 완료된 개념은 체크 마크 표시
```
