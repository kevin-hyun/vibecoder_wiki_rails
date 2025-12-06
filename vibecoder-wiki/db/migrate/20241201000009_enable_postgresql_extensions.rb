class EnablePostgresqlExtensions < ActiveRecord::Migration[7.2]
  def change
    # UUID 생성용
    enable_extension 'pgcrypto'
    
    # Full-Text Search용 (한국어 지원)
    enable_extension 'unaccent'
    enable_extension 'pg_trgm'
    
    # 실시간 기능용 (Supabase에서 사용)
    # enable_extension 'supabase_realtime'  # Supabase 에서 자동 활성화
  end
end