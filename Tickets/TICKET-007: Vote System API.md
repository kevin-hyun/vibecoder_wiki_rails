Description:
투표 시스템 API 구현

Acceptance Criteria:

- [ ] POST /api/explanations/[id]/vote - 투표
- [ ] 중복 투표 방지 (userId or IP)
- [ ] 실시간 voteCount 업데이트
- [ ] Firestore transaction 사용

Dependencies: TICKET-006

Business Logic:

- One vote per user per explanation
- Vote value: 1 (like) or -1 (dislike)
