class User < ApplicationRecord
  # Devise 모듈
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :omniauthable, omniauth_providers: [:google_oauth2]

  # Associations
  has_many :explanations, foreign_key: 'author_id', dependent: :destroy
  has_many :votes, dependent: :nullify
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_concepts, through: :bookmarks, source: :concept
  has_many :concept_views, dependent: :nullify
  has_many :user_activities, dependent: :destroy
  has_many :concepts, foreign_key: 'created_by', dependent: :destroy

  # Validations
  validates :display_name, presence: true, length: { maximum: 50 }
  validates :role, inclusion: { in: %w[user premium admin guest] }
  validates :theme, inclusion: { in: %w[light dark system] }
  validates :explanations_count, :total_votes, :concepts_contributed, 
            numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :set_default_display_name, on: :create
  before_create :set_uuid_primary_key

  # Scopes - PostgreSQL 최적화
  scope :active, -> { where('sign_in_count > 0') }
  scope :premium, -> { where(is_premium: true) }
  scope :admin, -> { where(role: 'admin') }
  scope :recent, -> { order(created_at: :desc) }
  scope :top_contributors, -> { order(explanations_count: :desc, total_votes: :desc) }

  # PostgreSQL Full-Text Search
  scope :search_by_name, ->(query) {
    return all if query.blank?
    where("to_tsvector('korean', display_name) @@ plainto_tsquery('korean', ?)", query)
  }

  # 비전공자 친화적 메소드들
  def admin?
    role == 'admin'
  end

  def premium_active?
    is_premium && (premium_expires_at.nil? || premium_expires_at.future?)
  end

  def beginner_level?
    explanations_count < 5 && total_votes < 20
  end

  def expert_level?
    explanations_count >= 20 || total_votes >= 100
  end

  def level_badge
    return '👑 관리자' if admin?
    return '💎 바이브 마스터' if premium_active?
    return '🌟 전문가' if expert_level?
    return '📝 활발한 멤버' if explanations_count >= 10
    return '🌱 새싹 멤버' if beginner_level?
    '👤 일반 멤버'
  end

  def contribution_stats
    {
      explanations: explanations_count,
      votes_received: total_votes,
      concepts_created: concepts_contributed,
      bookmarks: bookmarks.count,
      best_explanations: explanations.where(is_best_explanation: true).count
    }
  end

  # OAuth 관련 메소드
  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.display_name = auth.info.name || auth.info.email.split('@').first
      user.photo_url = auth.info.image
      user.provider = auth.provider
      user.uid = auth.uid
      user.password = Devise.friendly_token[0, 20]
    end
  end

  # 포인트 시스템 (게이미피케이션)
  def add_points(points, activity_type, target = nil)
    increment!(:total_votes, points)
    
    user_activities.create!(
      activity_type: activity_type,
      target_type: target&.class&.name,
      target_id: target&.id,
      points_earned: points,
      metadata: {
        total_points_before: total_votes - points,
        total_points_after: total_votes
      }
    )
  end

  # 실시간 알림용 채널
  def notification_channel
    "user_#{id}"
  end

  # PostgreSQL JSONB 활용 - 사용자 설정
  def preferences
    user_activities.where(activity_type: 'preferences_updated')
                  .last&.metadata || {}
  end

  def update_preferences!(new_preferences)
    user_activities.create!(
      activity_type: 'preferences_updated',
      metadata: new_preferences,
      points_earned: 0
    )
  end

  private

  def set_default_display_name
    self.display_name = email.split('@').first if display_name.blank? && email.present?
  end

  def set_uuid_primary_key
    self.id = SecureRandom.uuid if id.blank?
  end
end