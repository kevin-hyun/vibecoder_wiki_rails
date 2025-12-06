## TICKET-018-Admin-Dashboard

**Priority**: P1 | **Estimate**: 3h | **Assignee**: Dev

```
Description:
관리자 대시보드 기본 구현

Acceptance Criteria:
- [ ] 관리자 권한 체크 미들웨어
- [ ] 기본 통계 표시 (DAU, 총 설명 수)
- [ ] 개념 관리 (CRUD)
- [ ] 개념 등록/수정 시 관련 개념 선택 UI
- [ ] 최근 활동 로그

Dependencies: TICKET-004, TICKET-008

Route: app/admin/dashboard/page.tsx

Technical Notes:
- 관련 개념 선택 UI는 다중 선택 드롭다운 또는 검색 가능한 선택 컴포넌트
- 기존 개념들을 검색하여 관련 개념으로 연결 가능
- 관련 개념 관계는 양방향으로 자동 설정 (A가 B와 관련되면 B도 A와 관련)
```
