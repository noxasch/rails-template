# This will extend config gem to utilize rails credentials
module Config
  def self.load_files(*sources)
    config = Options.new

    # add settings sources
    [sources].flatten.compact.each do |source|
      config.add_source!(source)
    end

    load_credentials(config)
    config.add_source!(Sources::EnvSource.new(ENV)) if Config.use_env
    config.load!
    config
  end

  def self.load_credentials(config)
    if Rails.env.production? || Rails.env.staging?
      # Load and replace secrets from credentials
      config.add_source!(Rails.application.credentials.config.deep_stringify_keys)
    end
  end
end
