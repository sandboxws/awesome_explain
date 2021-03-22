AwesomeExplain.configure do |config|
  config.db_name = :ae
  config.db_path = Rails.root.join('log').to_s
  config.enabled = true
  config.active_record_enabled = true
  config.include_full_plan = false
  config.adapter = :postgres
  config.max_limit = :unlimited
  config.app_name = :rails
  config.logger = Rails.logger
  config.postgres_username = 'vagrant'
  config.postgres_password = 'vagrant'
  config.rails_path = Rails.root.to_s
end
