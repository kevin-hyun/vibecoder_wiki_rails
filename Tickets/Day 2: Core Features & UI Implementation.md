# Day 2: Core Features & UI Implementation

## TICKET-008: Google OAuth Integration

**Priority**: P0 | **Estimate**: 2h | **Assignee**: Dev

```
Description:
Google 로그인 구현 및 사용자 프로필 생성

Acceptance Criteria:
- [ ] 로그인/로그아웃 버튼 컴포넌트
- [ ] Firebase Auth 훅 생성 (useAuth)
- [ ] 신규 가입시 users 컬렉션에 프로필 자동 생성
- [ ] 세션 유지 (30일)

Dependencies: TICKET-002, TICKET-003

Components:
- /components/auth/LoginButton.tsx
- /hooks/useAuth.ts
```

## TICKET-009: Home Page Implementation

**Priority**: P0 | **Estimate**: 3h | **Assignee**: Dev

```
Description:
메인 홈페이지 구현

Acceptance Criteria:
- [ ] Hero 섹션 with 검색바
- [ ] 자동완성 검색 기능
- [ ] 오늘의 인기 개념 (3개 카드)
- [ ] 카테고리별 탐색 링크
- [ ] "개념 제안하기" 버튼 (로그인 시)
- [ ] 반응형 디자인

Dependencies: TICKET-003, TICKET-005

Route: app/page.tsx
```

## TICKET-010: Concept Detail Page

**Priority**: P0 | **Estimate**: 4h | **Assignee**: Dev

```
Description:
개념 상세 페이지 구현

Acceptance Criteria:
- [ ] 개념 정보 표시 (제목, 난이도, 카테고리)
- [ ] 설명 캐러셀 (Swiper.js)
- [ ] 설명 작성 폼
- [ ] 투표 버튼 기능
- [ ] "더보기" 설명 리스트

Dependencies: TICKET-005, TICKET-006, TICKET-008

Route: app/concept/[id]/page.tsx
```

## TICKET-011: Explanation Carousel Component

**Priority**: P1 | **Estimate**: 3h | **Assignee**: Dev

```
Description:
설명 캐러셀 컴포넌트 구현

Acceptance Criteria:
- [ ] Swiper.js 통합
- [ ] 투표순 상위 3개 표시
- [ ] 카드 디자인 (투표수, 작성자, 태그)
- [ ] 스와이프/버튼 네비게이션
- [ ] 모바일 터치 지원

Dependencies: TICKET-003

Component: /components/explanation/ExplanationCarousel.tsx
```

## TICKET-012-Explanation-Form-Component

**Priority**: P1 | **Estimate**: 2h | **Assignee**: Dev

```
Description:
설명 작성 폼 컴포넌트

Acceptance Criteria:
- [ ] 300자 제한 텍스트에어리어
- [ ] 실시간 글자수 표시
- [ ] 태그 선택 (최대 3개)
- [ ] 미리보기 기능
- [ ] 로그인 체크

Dependencies: TICKET-008

Component: /components/explanation/ExplanationForm.tsx
```

## TICKET-013: UI Components Guide Page

**Priority**: P2 | **Estimate**: 3h | **Assignee**: Dev

```
Description:
UI 컴포넌트 가이드 페이지

Acceptance Criteria:
- [ ] 컴포넌트 카테고리별 그룹핑
- [ ] 인터랙티브 모드 (hover 효과)
- [ ] 문서 모드 토글
- [ ] 컴포넌트 설명 및 사용 예시

Dependencies: TICKET-003

Route: app/ui-components/page.tsx
```

## TICKET-014: Search Functionality

**Priority**: P1 | **Estimate**: 2h | **Assignee**: Dev

```
Description:
검색 기능 구현

Acceptance Criteria:
- [ ] 실시간 검색어 자동완성
- [ ] 디바운싱 적용 (300ms)
- [ ] 검색 결과 드롭다운
- [ ] 키보드 네비게이션 지원

Dependencies: TICKET-005

Component: /components/search/SearchBar.tsx
```

## TICKET-015: Mobile Responsive Design

**Priority**: P1 | **Estimate**: 2h | **Assignee**: Dev

```
Description:
반응형 디자인 최적화

Acceptance Criteria:
- [ ] 모바일 네비게이션 메뉴
- [ ] 터치 친화적 버튼 크기
- [ ] 캐러셀 모바일 최적화
- [ ] 폼 요소 모바일 최적화

Dependencies: All UI tickets

Breakpoints:
- Mobile: < 640px
- Tablet: 640px - 1024px
- Desktop: > 1024px
```
