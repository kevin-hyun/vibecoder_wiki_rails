# Supabase 설정
Rails.application.config.after_initialize do
  if defined?(Supabase)
    Rails.logger.info "Initializing Supabase client..."
    
    # Supabase 클라이언트 설정
    Supabase.configure do |config|
      config.url = ENV['SUPABASE_URL']
      config.key = ENV['SUPABASE_ANON_KEY']
    end
    
    # 전역 Supabase 클라이언트
    SUPABASE_CLIENT = Supabase::Client.new(
      ENV['SUPABASE_URL'],
      ENV['SUPABASE_ANON_KEY']
    )
    
    Rails.logger.info "Supabase client initialized successfully"
  else
    Rails.logger.warn "Supabase gem not found. Real-time features will be disabled."
  end
end

# 실시간 기능을 위한 테이블 설정
class SupabaseRealtime
  REALTIME_TABLES = %w[
    explanations
    votes
    concepts
    user_activities
  ].freeze
  
  def self.enable_realtime!
    return unless defined?(SUPABASE_CLIENT)
    
    REALTIME_TABLES.each do |table|
      begin
        # Supabase에서 실시간 기능 활성화
        # 실제로는 Supabase 대시보드에서 설정하거나 SQL로 실행
        Rails.logger.info "Enabling realtime for table: #{table}"
      rescue => e
        Rails.logger.error "Failed to enable realtime for #{table}: #{e.message}"
      end
    end
  end
  
  def self.subscribe_to_changes(table, callback)
    return unless defined?(SUPABASE_CLIENT)
    
    SUPABASE_CLIENT
      .from(table)
      .on('*', callback)  # 모든 변경사항 (INSERT, UPDATE, DELETE)
      .subscribe
  end
end

# 애플리케이션 시작시 실시간 기능 활성화
Rails.application.config.after_initialize do
  if Rails.env.production? || Rails.env.development?
    SupabaseRealtime.enable_realtime!
  end
end