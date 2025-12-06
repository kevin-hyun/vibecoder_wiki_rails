# TICKET-BACKLOG-002: Enhanced Duplicate Check System

## 📋 Overview
현재 중복체크 시스템을 고도화하여 더 정확하고 사용자 친화적인 개념 추천 시스템으로 발전시키는 작업

## 🎯 Goals
- 유사한 개념 상세 정보 제공으로 사용자 경험 개선
- 정교한 유사성 판단 로직으로 정확도 향상
- 인텔리전트한 개념 추천 시스템 구축

## 📝 Current State
- ✅ 기본 중복체크 기능 (정확한 일치만 감지)
- ✅ 단순한 문자열 포함 관계로 유사 개념 감지
- ✅ Toast 알림으로 결과 표시
- ❌ 유사 개념의 구체적 정보 부족
- ❌ 단순한 유사성 판단 로직

## 📋 Sub-tickets

### TICKET-BACKLOG-002A: 유사한 개념 상세 정보 표시
**Priority**: High
**Effort**: 2-3 days

**Description**:
현재 "유사한 개념 2개 발견" 형태의 단순 알림을 구체적인 정보 제공으로 개선

**Tasks**:
- [ ] 유사 개념 리스트를 Toast 대신 Modal/Dropdown으로 표시
- [ ] 각 유사 개념별 상세 정보 표시 (제목, 설명, 유사도 점수)
- [ ] "이미 찾던 개념이 있나요?" UI 패턴 적용
- [ ] 모바일 반응형 디자인 적용

**Mockup**:
```
┌─────────────────────────────────────┐
│ 🔍 유사한 개념들을 찾았습니다        │
├─────────────────────────────────────┤
│ React Hooks (85% 유사)              │
│ React 함수형 컴포넌트에서...         │
│ [상세보기] [이 개념입니다]           │
├─────────────────────────────────────┤
│ React Context (65% 유사)            │  
│ React 전역 상태 관리를...            │
│ [상세보기] [이 개념입니다]           │
├─────────────────────────────────────┤
│ [아니요, 새로운 개념입니다]          │
└─────────────────────────────────────┘
```

### TICKET-BACKLOG-002B: 고도화된 유사성 판단 로직
**Priority**: High  
**Effort**: 3-4 days

**Description**:
현재 단순 문자열 포함(`includes()`) 방식을 다차원 유사도 계산으로 개선

**Tasks**:
- [ ] Levenshtein Distance 알고리즘 구현
- [ ] 키워드 기반 유사도 계산 (공통 키워드 가중치)
- [ ] 카테고리 기반 가중치 시스템 (같은 카테고리 +10점)
- [ ] 동의어 사전 구축 ("JS"↔"JavaScript", "API"↔"인터페이스")
- [ ] 복합 점수 계산 시스템 (문자열 + 키워드 + 카테고리)
- [ ] 유사도 임계값 설정 (50% 이상만 유사 개념으로 분류)

**Algorithm Example**:
```typescript
interface SimilarityScore {
  textSimilarity: number;    // 0-40점: Levenshtein + 문자열 포함
  keywordMatch: number;      // 0-30점: 공통 키워드 비율
  categoryBonus: number;     // 0-20점: 같은 카테고리
  synonymMatch: number;      // 0-10점: 동의어 매칭
  totalScore: number;        // 0-100점 총합
}
```

### TICKET-BACKLOG-002C: 유사 개념 네비게이션 기능
**Priority**: Medium
**Effort**: 1-2 days

**Description**:
유사 개념 클릭 시 해당 개념 페이지로 이동할 수 있는 네비게이션 기능

**Tasks**:
- [ ] 유사 개념 항목에 클릭 이벤트 추가
- [ ] 개념 ID를 통한 페이지 라우팅
- [ ] "이 개념입니다" 버튼으로 폼 자동 취소
- [ ] 뒤로가기 버튼 지원 (브라우저 히스토리)
- [ ] 새 탭에서 열기 옵션

### TICKET-BACKLOG-002D: 스마트 자동 제안 시스템
**Priority**: Low
**Effort**: 2-3 days

**Description**:
유사 개념 기반으로 태그, 키워드, 카테고리를 자동 제안하는 시스템

**Tasks**:
- [ ] 유사 개념들의 공통 키워드 추출
- [ ] 추천 태그 리스트 생성
- [ ] 카테고리 자동 제안 (유사 개념들의 다수결)
- [ ] 난이도 자동 추정 (유사 개념들의 평균)
- [ ] "추천 키워드 적용하기" 버튼
- [ ] 사용자 맞춤 학습 (승인된 제안 패턴 학습)

**UI Example**:
```
┌─────────────────────────────────────┐
│ 💡 추천 키워드                      │
├─────────────────────────────────────┤
│ [React] [프론트엔드] [JavaScript]    │
│ [함수형] [컴포넌트]                  │
│                                     │
│ 💡 추천 카테고리: 프론트엔드         │  
│ 💡 추천 난이도: 중급                │
│                                     │
│ [모두 적용] [선택 적용]              │
└─────────────────────────────────────┘
```

## 🔧 Technical Considerations

### Database Schema Updates
```typescript
// concepts collection 확장
interface ConceptDocument {
  // 기존 필드들...
  keywords: string[];        // 키워드 배열
  synonyms: string[];       // 동의어 배열
  relatedConcepts: string[]; // 연관 개념 ID들
}

// similarity_cache collection (성능 최적화)
interface SimilarityCache {
  concept1: string;
  concept2: string;
  similarity: number;
  lastCalculated: Timestamp;
}
```

### API Updates
```typescript
// /api/concepts/suggestions/check-duplicate
interface DuplicateCheckResponse {
  isDuplicate: boolean;
  exactMatch?: ConceptMatch;
  similarConcepts: SimilarConceptMatch[]; // 확장
}

interface SimilarConceptMatch {
  id: string;
  title: string;
  description: string;
  similarity: SimilarityScore; // 상세 점수
  matchReasons: string[];      // ["키워드 일치", "같은 카테고리"]
}
```

## 📊 Success Metrics
- [ ] 유사 개념 발견 정확도 80% 이상
- [ ] 사용자가 유사 개념을 통해 원하는 개념을 찾는 비율 40% 이상
- [ ] 중복 제안 감소율 60% 이상
- [ ] 자동 제안 키워드 채택률 30% 이상

## 🚀 Implementation Order
1. **TICKET-BACKLOG-002B** (유사성 로직) - 핵심 엔진
2. **TICKET-BACKLOG-002A** (상세 정보 UI) - 사용자 경험
3. **TICKET-BACKLOG-002C** (네비게이션) - 편의 기능
4. **TICKET-BACKLOG-002D** (자동 제안) - 부가 가치

## 💭 Future Enhancements
- AI 기반 개념 유사도 계산 (Vector Embeddings)
- 사용자 행동 기반 개인화 추천
- 개념 간 관계 그래프 시각화
- 커뮤니티 태깅을 통한 유사도 개선