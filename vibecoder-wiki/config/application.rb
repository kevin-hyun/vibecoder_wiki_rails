require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VibecoderWiki
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments/, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # 한국 시간대 설정
    config.time_zone = 'Seoul'

    # 비전공자 친화적 설정
    config.i18n.default_locale = :ko
    config.i18n.available_locales = [:ko, :en]

    # UUID 기본키 설정
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # ViewComponent 설정
    config.view_component.preview_paths << "#{Rails.root}/test/components/previews"
    config.view_component.show_previews = true

    # ActionCable 설정
    config.action_cable.mount_path = '/cable'

    # CORS 설정 (실시간 기능용)
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*' # 개발용, 프로덕션에서는 도메인 제한 필요
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true
      end
    end

    # 보안 설정
    config.force_ssl = false # 개발환경에서는 false
    
    # 세션 설정
    config.session_store :cookie_store, key: '_vibecoder_wiki_session'
    
    # 로깅 설정
    config.log_level = :info
    config.log_tags = [:request_id]

    # 캐싱 설정
    config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }

    # 작업 큐 설정
    config.active_job.queue_adapter = :sidekiq
    
    # 파일 업로드 설정
    config.active_storage.variant_processor = :mini_magick
  end
end