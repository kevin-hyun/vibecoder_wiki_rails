# TICKET-009a: Main Page Ranking System

**Priority**: P2 | **Estimate**: 3h | **Assignee**: Dev | **Day**: 2

```
Description:
메인 페이지 실시간 랭킹 시스템 구현

Acceptance Criteria:
- [ ] 랭킹 계산 로직 구현 (3개 카테고리)
- [ ] Firestore에 랭킹 데이터 저장
- [ ] 10분마다 업데이트하는 Cloud Function (Post-MVP)
- [ ] 메인 페이지에 TOP 3 표시
- [ ] 전체 순위 페이지 링크
- [ ] 모바일 반응형 디자인

Dependencies: TICKET-009, TICKET-008

Data Structure:
interface UserStats {
  userId: string;
  monthlyExplanations: number;
  monthlyVotes: number;
  interactionScore: number;
  lastUpdated: Timestamp;
}

interface Rankings {
  category: 'explanations' | 'votes' | 'interaction';
  period: 'daily' | 'weekly' | 'monthly';
  topUsers: Array<{
    rank: number;
    userId: string;
    userName: string;
    score: number;
  }>;
  lastUpdated: Timestamp;
}

Interaction Score Calculation:
- Write explanation: +10 points
- Vote on explanation: +1 point
- Get best explanation: +20 points
- Suggest concept: +15 points
- Daily login: +2 points

Technical Notes:
- MVP: Calculate on page load (with 5min cache)
- Post-MVP: Cloud Function for real-time updates
- Use Firestore compound queries for efficiency
- Consider using Firestore aggregation queries
- Milestone achievements stored in separate subcollection
- Use Firestore transactions when updating milestones

Component:
- /components/ranking/TopRankings.tsx
- /app/rankings/page.tsx (전체 순위)
```
