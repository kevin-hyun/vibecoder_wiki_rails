## TICKET-021a-Google-AdSense-Integration

**Priority**: P1 | **Estimate**: 2h | **Assignee**: Dev

```
Description:
Google AdSense 통합 및 프리미엄 광고 제거 기능

Acceptance Criteria:
- [ ] AdSense 계정 설정 및 승인
- [ ] GoogleAd 컴포넌트 생성
- [ ] Smart Progressive 광고 배치 로직 구현
- [ ] 프리미엄 사용자 광고 제거 기능
- [ ] 세션별 페이지뷰 추적 시스템
- [ ] 반응형 광고 설정
- [ ] 관리자 계정 한정 광고 제거

Dependencies: TICKET-008 (Auth)

Technical Notes:
- Progressive 광고 로직:
  * 1-2 페이지: 1개 광고
  * 3-5 페이지: 2개 광고
  * 6-10 페이지: 2.5개 광고
  * 10+ 페이지: 3개 광고
- 광고 위치: 설명 캐러셀 직후, 페이지 하단
- 프리미엄 사용자는 모든 광고 제거

Component:
- /components/ads/GoogleAd.tsx
- /hooks/usePageViewTracking.ts
```
