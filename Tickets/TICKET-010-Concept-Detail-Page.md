## TICKET-010-Concept-Detail-Page

**Priority**: P0 | **Estimate**: 4h | **Assignee**: Dev

```
Description:
개념 상세 페이지 구현

Acceptance Criteria:
- [ ] 개념 정보 표시 (제목, 난이도, 카테고리)
- [ ] 관련 개념 링크 섹션 (있을 경우)
- [ ] 설명 캐러셀 (Swiper.js)
- [ ] 설명 작성 폼
- [ ] 투표 버튼 기능
- [ ] "더보기" 설명 리스트

Dependencies: TICKET-004, TICKET-005, TICKET-006, TICKET-008

Route: app/concept/[id]/page.tsx

Technical Notes:
- 관련 개념은 getRelatedConcepts() 함수를 사용하여 가져옴
- 관련 개념이 있을 경우에만 섹션 표시
- 관련 개념 클릭 시 해당 개념 상세 페이지로 이동
```
