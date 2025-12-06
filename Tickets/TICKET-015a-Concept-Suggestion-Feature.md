# TICKET-015a-Concept-Suggestion-Feature

**Priority**: P1 | **Estimate**: 3h | **Assignee**: Dev | **Day**: 2

```
Description:
개념 제안 시스템 구현

Acceptance Criteria:
- [ ] 개념 제안 폼 컴포넌트
- [ ] 중복 검사 API
- [ ] 제안 제출 API
- [ ] 내 제안 목록 페이지
- [ ] 관리자 검토 큐 페이지

Dependencies: TICKET-008

Components:
- /components/concept/SuggestionForm.tsx
- /app/concepts/suggest/page.tsx
- /app/profile/suggestions/page.tsx
- /app/admin/suggestions/page.tsx

API Endpoints:
- POST /api/concepts/suggestions
- GET /api/concepts/suggestions/check-duplicate
- GET /api/concepts/suggestions/my
- PUT /api/concepts/suggestions/[id]/approve
- PUT /api/concepts/suggestions/[id]/reject

Technical Notes:
- 새 개념 게시글 작석한 자에게 "개념 개척자" 뱃지 부여
```
