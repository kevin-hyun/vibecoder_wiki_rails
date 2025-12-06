-- 바이브코더 위키 RLS 정책 설정
-- 이 파일을 Supabase SQL Editor에서 실행하세요

-- 1. Users 테이블 정책
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 다른 사용자 정보를 볼 수 있음 (공개 프로필)
CREATE POLICY "Anyone can view user profiles" ON users
FOR SELECT USING (true);

-- 사용자는 자신의 정보만 수정 가능
CREATE POLICY "Users can update own profile" ON users
FOR UPDATE USING (auth.uid()::text = id);

-- 2. Concepts 테이블 정책
ALTER TABLE concepts ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 개념을 볼 수 있음
CREATE POLICY "Anyone can view concepts" ON concepts
FOR SELECT USING (true);

-- 로그인한 사용자는 개념 생성 가능
CREATE POLICY "Authenticated users can create concepts" ON concepts
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 작성자나 관리자만 개념 수정 가능
CREATE POLICY "Authors and admins can update concepts" ON concepts
FOR UPDATE USING (
  auth.uid()::text = created_by OR 
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid()::text 
    AND users.role = 'admin'
  )
);

-- 3. Explanations 테이블 정책
ALTER TABLE explanations ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 설명을 볼 수 있음
CREATE POLICY "Anyone can view explanations" ON explanations
FOR SELECT USING (true);

-- 로그인한 사용자는 설명 작성 가능
CREATE POLICY "Authenticated users can create explanations" ON explanations
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 작성자나 관리자만 설명 수정 가능
CREATE POLICY "Authors and admins can update explanations" ON explanations
FOR UPDATE USING (
  auth.uid()::text = author_id OR 
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid()::text 
    AND users.role = 'admin'
  )
);

-- 작성자나 관리자만 설명 삭제 가능
CREATE POLICY "Authors and admins can delete explanations" ON explanations
FOR DELETE USING (
  auth.uid()::text = author_id OR 
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid()::text 
    AND users.role = 'admin'
  )
);

-- 4. Votes 테이블 정책
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 투표를 볼 수 있음
CREATE POLICY "Anyone can view votes" ON votes
FOR SELECT USING (true);

-- 로그인한 사용자 또는 익명 사용자(IP 기반)가 투표 가능
CREATE POLICY "Anyone can vote" ON votes
FOR INSERT WITH CHECK (true);

-- 투표자만 자신의 투표 수정/삭제 가능
CREATE POLICY "Voters can update own votes" ON votes
FOR UPDATE USING (
  (auth.uid() IS NOT NULL AND auth.uid()::text = user_id) OR
  (auth.uid() IS NULL AND user_id IS NULL)
);

CREATE POLICY "Voters can delete own votes" ON votes
FOR DELETE USING (
  (auth.uid() IS NOT NULL AND auth.uid()::text = user_id) OR
  (auth.uid() IS NULL AND user_id IS NULL)
);

-- 5. Bookmarks 테이블 정책
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 북마크만 볼 수 있음
CREATE POLICY "Users can view own bookmarks" ON bookmarks
FOR SELECT USING (auth.uid()::text = user_id);

-- 로그인한 사용자는 북마크 생성 가능
CREATE POLICY "Authenticated users can create bookmarks" ON bookmarks
FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- 사용자는 자신의 북마크만 삭제 가능
CREATE POLICY "Users can delete own bookmarks" ON bookmarks
FOR DELETE USING (auth.uid()::text = user_id);

-- 6. Concept Views 테이블 정책
ALTER TABLE concept_views ENABLE ROW LEVEL SECURITY;

-- 통계 목적으로 모든 사용자가 조회 가능 (개인 식별 정보 제외)
CREATE POLICY "Anyone can view concept statistics" ON concept_views
FOR SELECT USING (true);

-- 모든 사용자(익명 포함)가 조회 기록 생성 가능
CREATE POLICY "Anyone can create view records" ON concept_views
FOR INSERT WITH CHECK (true);

-- 7. User Activities 테이블 정책
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 활동만 볼 수 있음
CREATE POLICY "Users can view own activities" ON user_activities
FOR SELECT USING (auth.uid()::text = user_id);

-- 관리자는 모든 활동 조회 가능
CREATE POLICY "Admins can view all activities" ON user_activities
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid()::text 
    AND users.role = 'admin'
  )
);

-- 시스템이 활동 기록 생성
CREATE POLICY "System can create activity records" ON user_activities
FOR INSERT WITH CHECK (true);

-- 8. Concept Tags 테이블 정책
ALTER TABLE concept_tags ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 태그를 볼 수 있음
CREATE POLICY "Anyone can view tags" ON concept_tags
FOR SELECT USING (true);

-- 로그인한 사용자는 태그 생성 가능
CREATE POLICY "Authenticated users can create tags" ON concept_tags
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 태그 수정/삭제는 관리자만 가능
CREATE POLICY "Admins can manage tags" ON concept_tags
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid()::text 
    AND users.role = 'admin'
  )
);

-- 실시간 기능을 위한 Realtime 활성화
ALTER PUBLICATION supabase_realtime ADD TABLE concepts;
ALTER PUBLICATION supabase_realtime ADD TABLE explanations;
ALTER PUBLICATION supabase_realtime ADD TABLE votes;
ALTER PUBLICATION supabase_realtime ADD TABLE user_activities;