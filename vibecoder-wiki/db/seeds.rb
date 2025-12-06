# 바이브코더 위키 시드 데이터 - 비전공자 친화적 IT 개념들

puts "🌱 바이브코더 위키 시드 데이터 생성 시작..."

# 관리자 사용자 생성
admin_user = User.find_or_create_by!(email: 'admin@vibecoder.wiki') do |user|
  user.display_name = '바이브코더 관리자'
  user.role = 'admin'
  user.password = 'password123!'
  user.password_confirmation = 'password123!'
  user.is_premium = true
  user.premium_expires_at = 1.year.from_now
end

puts "👑 관리자 계정 생성: #{admin_user.email}"

# 테스트 사용자들 생성
test_users = [
  {
    email: 'beginner@example.com',
    display_name: '초보자김씨',
    role: 'user'
  },
  {
    email: 'premium@example.com', 
    display_name: '프리미엄박씨',
    role: 'premium',
    is_premium: true,
    premium_expires_at: 6.months.from_now
  },
  {
    email: 'expert@example.com',
    display_name: '전문가이씨', 
    role: 'user'
  }
]

created_users = test_users.map do |user_data|
  User.find_or_create_by!(email: user_data[:email]) do |user|
    user.display_name = user_data[:display_name]
    user.role = user_data[:role]
    user.password = 'password123!'
    user.password_confirmation = 'password123!'
    user.is_premium = user_data[:is_premium] || false
    user.premium_expires_at = user_data[:premium_expires_at]
  end
end

puts "👥 테스트 사용자 #{created_users.size}명 생성 완료"

# IT 기초 개념들 (비전공자 친화적)
it_concepts = [
  {
    title: 'API',
    simple_definition: '서로 다른 프로그램들이 대화할 수 있게 해주는 번역기 같은 것이에요',
    description: '레스토랑에서 웨이터가 주방과 손님 사이를 연결해주는 것처럼, API는 앱과 서버 사이를 연결해줘요. 예를 들어, 날씨 앱이 기상청 데이터를 가져올 때 API를 사용해요.',
    category: 'it',
    level: 2,
    why_important: '모든 앱과 웹사이트가 다른 서비스와 연결될 때 필요해서 개발할 때 반드시 알아야 하는 개념이에요',
    is_popular: true,
    is_verified: true
  },
  {
    title: 'Git',
    simple_definition: '코드의 변경사항을 추적하고 저장해주는 시간여행 도구예요',
    description: '구글 문서의 버전 기록 기능과 비슷해요. 코드를 수정할 때마다 스냅샷을 찍어두어서, 언제든 이전 버전으로 돌아갈 수 있어요. 여러 명이 함께 작업할 때도 충돌 없이 협업할 수 있게 해줘요.',
    category: 'it',
    level: 1,
    why_important: '개발자들이 협업할 때 필수도구이고, 코드를 안전하게 관리할 수 있어요',
    is_popular: true,
    is_verified: true
  },
  {
    title: '프론트엔드',
    simple_definition: '사용자가 직접 보고 클릭할 수 있는 화면 부분을 만드는 일이에요',
    description: '웹사이트나 앱에서 우리가 실제로 보는 버튼, 메뉴, 이미지 등을 만드는 것이 프론트엔드예요. 마치 상점의 진열장과 계산대처럼, 고객이 직접 접하는 부분을 담당해요.',
    category: 'it',
    level: 1,
    why_important: '사용자 경험을 직접 만드는 부분이라 비즈니스 성공에 중요한 역할을 해요',
    is_verified: true
  },
  {
    title: '백엔드',
    simple_definition: '사용자가 보지 못하는 뒤편에서 데이터를 처리하고 저장하는 일이에요',
    description: '레스토랑의 주방과 비슷해요. 손님은 보지 못하지만 주문을 받아 요리를 만들고, 재료를 관리하는 곳이에요. 로그인, 결제, 데이터 저장 등 핵심 기능들을 처리해요.',
    category: 'it',
    level: 1,
    why_important: '앱의 핵심 기능과 보안을 담당하는 중요한 부분이에요',
    is_verified: true
  },
  {
    title: '데이터베이스',
    simple_definition: '정보를 체계적으로 저장하고 찾을 수 있게 정리해둔 디지털 창고예요',
    description: '도서관과 비슷해요. 책들이 분류번호로 정리되어 있어서 원하는 책을 빠르게 찾을 수 있듯이, 데이터베이스도 정보를 규칙에 따라 저장해서 필요할 때 쉽게 찾을 수 있어요.',
    category: 'it',
    level: 2,
    why_important: '모든 앱과 웹사이트의 정보를 안전하게 보관하는 핵심 기술이에요'
  },
  {
    title: 'HTTP',
    simple_definition: '인터넷에서 정보를 주고받기 위한 약속된 규칙이에요',
    description: '우편 시스템과 비슷해요. 편지에 주소를 쓰고 우표를 붙이는 규칙이 있듯이, 인터넷에서도 정보를 안전하게 전달하기 위한 규칙이 HTTP예요. 웹사이트 주소가 http://로 시작하는 이유죠.',
    category: 'it',
    level: 2,
    why_important: '모든 웹 통신의 기본이 되는 핵심 프로토콜이에요'
  }
]

# 창업/스타트업 개념들
startup_concepts = [
  {
    title: 'MVP',
    simple_definition: '고객에게 핵심 가치를 전달할 수 있는 가장 간단한 형태의 제품이에요',
    description: '완벽한 집을 짓기 전에 텐트부터 시작하는 것과 같아요. 모든 기능을 다 만들기 전에, 가장 중요한 기능만으로 고객의 반응을 먼저 확인해보는 전략이에요.',
    category: 'startup',
    level: 1,
    why_important: '시간과 비용을 절약하면서 시장의 니즈를 빠르게 확인할 수 있어요',
    is_popular: true,
    is_verified: true
  },
  {
    title: '린 스타트업',
    simple_definition: '낭비를 최소화하면서 빠르게 학습하고 개선해나가는 창업 방법론이에요',
    description: '요리를 배울 때 한 번에 완벽한 요리를 만들려고 하지 않고, 간단한 요리부터 시작해서 계속 개선해나가는 것과 같아요. 고객의 피드백을 받고 빠르게 수정해나가는 방식이에요.',
    category: 'startup', 
    level: 2,
    why_important: '실패 확률을 줄이고 성공까지의 시간을 단축시킬 수 있어요'
  },
  {
    title: '피벗',
    simple_definition: '기존 사업 방향이 잘못되었을 때 새로운 방향으로 전환하는 것이에요',
    description: '길을 가다가 막다른 길을 만났을 때 다른 길로 바꿔가는 것과 같아요. 트위터는 원래 팟캐스트 플랫폼이었지만 소셜미디어로 피벗해서 성공했어요.',
    category: 'startup',
    level: 2,
    why_important: '실패를 성공으로 바꿀 수 있는 중요한 전략적 선택이에요'
  }
]

# UI/UX 개념들
ui_concepts = [
  {
    title: 'UX',
    simple_definition: '사용자가 제품을 사용할 때 느끼는 전체적인 경험이에요',
    description: '레스토랑 경험과 비슷해요. 음식 맛뿐만 아니라 서비스, 분위기, 접근성 등 모든 것이 고객 경험에 영향을 주죠. UX도 앱이나 웹사이트를 사용하는 전 과정에서의 사용자 감정과 만족도를 다뤄요.',
    category: 'ui',
    level: 1,
    why_important: '좋은 UX는 고객 만족도와 재방문율을 크게 높여줘요',
    is_verified: true
  },
  {
    title: 'UI',
    simple_definition: '사용자가 직접 보고 클릭하는 버튼, 메뉴 등의 시각적 요소예요',
    description: '자동차의 계기판과 같아요. 속도계, 연료계, 핸들, 페달 등 운전자가 직접 보고 조작하는 모든 것들이 UI예요. 웹사이트에서는 버튼, 메뉴, 입력창 등이 UI에 해당해요.',
    category: 'ui',
    level: 1,
    why_important: '사용자가 제품을 쉽고 편리하게 사용할 수 있게 해주는 핵심 요소예요',
    is_verified: true
  },
  {
    title: '와이어프레임',
    simple_definition: '웹사이트나 앱의 뼈대를 그려놓은 설계도예요',
    description: '집을 짓기 전에 그리는 도면과 같아요. 어디에 무엇이 들어갈지, 방의 크기와 위치는 어떻게 할지를 간단한 선으로 그려놓는 것이 와이어프레임이에요.',
    category: 'ui',
    level: 2,
    why_important: '개발하기 전에 구조를 미리 정해서 시간과 비용을 절약할 수 있어요'
  }
]

# 비즈니스 개념들
business_concepts = [
  {
    title: 'SaaS',
    simple_definition: '인터넷으로 제공되는 소프트웨어 서비스예요',
    description: 'CD로 프로그램을 사서 컴퓨터에 설치하는 대신, 넷플릭스처럼 인터넷으로 접속해서 사용하는 소프트웨어예요. 구글 문서, 노션, 슬랙 등이 대표적인 SaaS예요.',
    category: 'business',
    level: 2,
    why_important: '구독 기반으로 안정적인 수익을 만들 수 있는 비즈니스 모델이에요',
    is_popular: true
  },
  {
    title: 'B2B',
    simple_definition: '기업이 다른 기업에게 제품이나 서비스를 파는 사업이에요',
    description: '도매업과 비슷해요. 일반 소비자가 아닌 다른 회사를 고객으로 하는 비즈니스예요. 예를 들어, 회계 프로그램을 회사에 파는 것이 B2B예요.',
    category: 'business',
    level: 1,
    why_important: '거래 규모가 크고 장기적인 관계를 맺을 수 있어서 안정적이에요'
  },
  {
    title: 'B2C',
    simple_definition: '기업이 개인 소비자에게 직접 제품이나 서비스를 파는 사업이에요',
    description: '동네 마트나 온라인 쇼핑몰처럼 일반 사람들을 대상으로 하는 비즈니스예요. 넷플릭스, 쿠팡, 배달의민족 등이 B2C 서비스예요.',
    category: 'business',
    level: 1,
    why_important: '시장 규모가 크고 빠른 성장이 가능해요'
  }
]

# 모든 개념 생성
all_concepts = it_concepts + startup_concepts + ui_concepts + business_concepts

all_concepts.each_with_index do |concept_data, index|
  concept = Concept.find_or_create_by!(title: concept_data[:title]) do |c|
    c.simple_definition = concept_data[:simple_definition]
    c.description = concept_data[:description]
    c.category = concept_data[:category]
    c.level = concept_data[:level]
    c.why_important = concept_data[:why_important]
    c.is_popular = concept_data[:is_popular] || false
    c.is_verified = concept_data[:is_verified] || false
    c.view_count = rand(10..500)  # 랜덤 조회수
    c.average_rating = rand(3.0..5.0).round(1)
    c.created_by = admin_user.id
    c.slug = concept_data[:title].downcase.gsub(/[^a-z0-9]/, '-')
  end
  
  # 각 개념에 태그 추가
  tags = case concept_data[:category]
         when 'it'
           ['기초개념', '개발', '프로그래밍']
         when 'startup'
           ['창업', '스타트업', '비즈니스전략']
         when 'ui'
           ['디자인', 'UX디자인', '사용자경험']
         when 'business'
           ['비즈니스모델', '수익모델', '경영']
         end
  
  # 초급 개념에는 추가 태그
  tags += ['초보추천', '쉬운설명'] if concept_data[:level] == 1
  
  tags.each do |tag|
    concept.concept_tags.find_or_create_by!(tag: tag)
  end
  
  puts "📝 개념 생성: #{concept.title} (#{concept.category})"
end

puts "📚 총 #{all_concepts.size}개 개념 생성 완료"

# 각 개념에 설명 추가 (비전공자 친화적)
explanations_data = [
  {
    concept_title: 'API',
    explanations: [
      {
        content: 'API는 음식점에서 웨이터가 하는 일과 비슷해요. 손님(앱)이 주문을 하면 웨이터(API)가 주방(서버)에 전달하고, 요리가 나오면 다시 손님에게 가져다 주죠.',
        simple_analogy: '웨이터가 손님과 주방 사이에서 주문과 음식을 전달해주는 것처럼, API도 앱과 서버 사이를 연결해줘요.',
        example: '카카오맵 앱에서 길찾기를 하면, 앱이 교통정보 API를 통해 실시간 교통상황을 가져와서 보여줍니다.',
        difficulty_level: 'beginner',
        author: created_users[0]
      },
      {
        content: 'API는 프로그램들이 서로 소통할 수 있게 해주는 다리예요. 마치 번역기처럼 서로 다른 언어를 쓰는 프로그램들이 대화할 수 있게 도와줘요.',
        simple_analogy: '서로 다른 나라 사람들이 번역기를 통해 대화하는 것처럼, 다른 프로그램들도 API를 통해 소통해요.',
        example: '인스타그램에서 페이스북으로 사진을 공유할 때, API가 두 앱 사이의 데이터 전송을 담당합니다.',
        difficulty_level: 'intermediate',
        author: created_users[1]
      }
    ]
  },
  {
    concept_title: 'Git',
    explanations: [
      {
        content: 'Git은 구글 드라이브의 버전 기록과 비슷해요. 문서를 수정할 때마다 이전 버전들이 저장되어서, 언제든 예전 버전으로 돌아갈 수 있어요.',
        simple_analogy: '레고 조립 과정을 사진으로 찍어두는 것처럼, 코드 변경 과정을 기록해둬요.',
        example: '3명의 개발자가 같은 앱을 만들 때, 각자 다른 기능을 개발하고 Git으로 합쳐요.',
        difficulty_level: 'beginner',
        author: created_users[2]
      }
    ]
  },
  {
    concept_title: 'MVP',
    explanations: [
      {
        content: 'MVP는 아이디어를 검증하기 위한 가장 간단한 버전이에요. 완벽한 제품을 만들기 전에 핵심 기능만으로 고객 반응을 확인하는 거죠.',
        simple_analogy: '새로운 요리 레시피를 개발할 때, 먼저 가족들에게 간단한 버전을 해줘보고 반응을 확인하는 것과 같아요.',
        example: '드롭박스는 처음에 실제 제품 없이 동영상만으로 아이디어를 설명해서 관심도를 측정했어요.',
        difficulty_level: 'beginner',
        author: admin_user
      }
    ]
  }
]

explanations_data.each do |data|
  concept = Concept.find_by(title: data[:concept_title])
  next unless concept
  
  data[:explanations].each do |exp_data|
    explanation = concept.explanations.create!(
      content: exp_data[:content],
      simple_analogy: exp_data[:simple_analogy],
      example: exp_data[:example],
      difficulty_level: exp_data[:difficulty_level],
      author: exp_data[:author],
      vote_count: rand(0..20),
      helpfulness_score: rand(60..95),
      clarity_score: rand(70..100),
      tags: ['일상비유', '예시포함', '초보추천'].sample(rand(1..3))
    )
    
    # 일부 설명을 베스트로 설정
    if rand < 0.3  # 30% 확률로 베스트 설명
      explanation.update!(is_best_explanation: true)
    end
    
    puts "  💬 설명 추가: #{concept.title} - #{explanation.content.truncate(30)}"
  end
end

# 투표 데이터 생성
puts "🗳️  투표 데이터 생성 중..."

Explanation.find_each do |explanation|
  # 각 설명에 랜덤한 투표 추가
  vote_count = rand(0..15)
  
  vote_count.times do
    voter = [created_users.sample, nil].sample  # 50% 확률로 익명 투표
    vote_type = ['helpful', 'difficult'].sample
    
    # 중복 투표 방지
    existing_vote = if voter
                     explanation.votes.find_by(user: voter)
                   else
                     nil
                   end
    
    next if existing_vote
    
    explanation.votes.create!(
      user: voter,
      vote_type: vote_type,
      ip_address: voter ? nil : "192.168.1.#{rand(1..254)}",
      reason: vote_type == 'helpful' ? 
              ['이해하기 쉬워요', '좋은 비유예요', '실용적이에요'].sample :
              ['좀 더 쉽게 설명해주세요', '예시가 더 필요해요'].sample
    )
  end
  
  # 투표 수 업데이트
  explanation.update_vote_counts!
end

# 북마크 데이터 생성
puts "📚 북마크 데이터 생성 중..."

created_users.each do |user|
  # 각 사용자가 2-5개 개념을 북마크
  bookmarked_concepts = Concept.all.sample(rand(2..5))
  
  bookmarked_concepts.each do |concept|
    user.bookmarks.find_or_create_by!(concept: concept)
  end
end

# 조회 기록 생성
puts "👀 조회 기록 생성 중..."

Concept.find_each do |concept|
  # 각 개념에 랜덤한 조회 기록 추가
  view_count = rand(5..50)
  
  view_count.times do
    viewer = [created_users.sample, nil].sample  # 50% 확률로 익명 조회
    viewed_at = rand(30.days.ago..Time.current)
    
    concept.concept_views.create!(
      user: viewer,
      ip_address: "192.168.1.#{rand(1..254)}",
      viewed_at: viewed_at
    )
  end
end

# 사용자 활동 기록 생성
puts "🎯 사용자 활동 기록 생성 중..."

created_users.each do |user|
  # 설명 작성 활동
  user.explanations.each do |explanation|
    UserActivity.create!(
      user: user,
      activity_type: 'explanation_created',
      target: explanation,
      points_earned: 2,
      metadata: {
        concept_title: explanation.concept.title,
        content_length: explanation.content.length
      }
    )
  end
  
  # 투표 활동
  user.votes.each do |vote|
    UserActivity.create!(
      user: user,
      activity_type: 'vote_cast',
      target: vote.explanation,
      points_earned: 1,
      metadata: {
        vote_type: vote.vote_type,
        concept_title: vote.explanation.concept.title
      }
    )
  end
  
  # 사용자 통계 업데이트
  user.update!(
    explanations_count: user.explanations.count,
    total_votes: user.user_activities.sum(:points_earned),
    concepts_contributed: user.concepts.count
  )
end

puts "✅ 시드 데이터 생성 완료!"
puts
puts "📊 생성된 데이터 요약:"
puts "- 사용자: #{User.count}명 (관리자 1명, 테스트 사용자 #{created_users.size}명)"
puts "- 개념: #{Concept.count}개"
puts "  - IT 기초: #{Concept.where(category: 'it').count}개"
puts "  - 창업: #{Concept.where(category: 'startup').count}개"  
puts "  - UI/UX: #{Concept.where(category: 'ui').count}개"
puts "  - 비즈니스: #{Concept.where(category: 'business').count}개"
puts "- 설명: #{Explanation.count}개"
puts "- 투표: #{Vote.count}개"
puts "- 북마크: #{Bookmark.count}개"
puts "- 조회 기록: #{ConceptView.count}개"
puts "- 사용자 활동: #{UserActivity.count}개"
puts
puts "🎉 바이브코더 위키가 준비되었어요!"
puts "🔑 관리자 계정: admin@vibecoder.wiki / password123!"
puts "👥 테스트 계정들: beginner@example.com, premium@example.com, expert@example.com / password123!"