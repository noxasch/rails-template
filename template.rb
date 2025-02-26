
say "Adding necessary gems"
# development test gem
run "bundle add brakeman -g \"development, test\" --require=false --skip-install", verbose: false
run "bundle add bullet -g \"development, test\" --skip-install", verbose: false
run "bundle add rspec-rails -g \"development, test\"", verbose: false
run "bundle add factory_bot_rails -g \"development, test\" --require=false --skip-install", verbose: false
run "bundle add brakeman -g \"development, test\" --require=false --skip-install", verbose: false
run "bundle add rubocop -g \"development, test\" --require=false --skip-install", verbose: false
run "bundle add rubocop-performance -g \"development, test\" --require=false --skip-install", verbose: false
run "bundle add rubocop-rails -g \"development, test\" --require=false --skip-install", verbose: false
run "bundle add rubocop-rspec -g \"development, test\" --require=false --skip-install", verbose: false
run "bundle add brakeman -g \"development, test\" --require=false --skip-install", verbose: false

# development gem
run "bundle add annotate -g \"development\"", verbose: false
run "bundle add database_consistency -g \"development\" --require=false --skip-install", verbose: false

# test gem
run "bundle add rspec-json_expectations -g \"test\" --require=false --skip-install", verbose: false
run "bundle add rspec_junit_formatter -g \"test\" --require=false --skip-install", verbose: false
run "bundle add shoulda-matchers -g \"test\" --require=false --skip-install", verbose: false
run "bundle add simplecov -g \"test\" --require=false", verbose: false
run "bundle add simplecov-cobertura -g \"test\" --require=false --skip-install", verbose: false
run "bundle add ruby-prof -g \"test\" --require=false --skip-install", verbose: false
run "bundle add test-prof -g \"test\" --require=false --skip-install", verbose: false
run "bundle add wisper-rspec -g \"test\" --require=false --skip-install", verbose: false

# gem
run "bundle add config --skip-install", verbose: false
run "bundle add devise --skip-install", verbose: false
run "bundle add devise_invitable --skip-install", verbose: false
run "bundle add action_policy --skip-install", verbose: false
run "bundle add friendly_id --skip-install", verbose: false
run "bundle add hash_to_struct --skip-install", verbose: false
run "bundle add mutations --skip-install", verbose: false
run "bundle add oj_serializers --skip-install", verbose: false
run "bundle add pagy --skip-install", verbose: false
run "bundle add phony_rails --skip-install", verbose: false

if yes?("Would you like use sidekiq?")
  run "bundle add sidekiq --skip-install", verbose: false
end

if yes?("Would you like to use shrine for file attachment?")
  run "bundle add image_processing --skip-install", verbose: false
  run "bundle add marcel --skip-install", verbose: false
  run "bundle add ruby-vips --skip-install", verbose: false
  run "bundle add shrine --skip-install", verbose: false

  if yes?("Would you like to use s3 or s3 compatible service?")
    run "bundle add aws-sdk-s3 --skip-install"

    file "app/components/foo.rb", <<-CODE
      require "shrine"
      require "shrine/storage/file_system"
      require "shrine/storage/memory"
      require "image_processing/vips"

      if Rails.env.test?
        Shrine.storages = {
          cache: Shrine::Storage::Memory.new,
          store: Shrine::Storage::Memory.new
        }
      elsif Rails.env.development?
        Shrine.storages = {
          cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"), # temporary
          store: Shrine::Storage::FileSystem.new("public", prefix: "uploads"),       # permanent
        }
      elsif ENV['SECRET_KEY_BASE_DUMMY'] # handle rails precompile
        Shrine.storages = {
          cache: Shrine::Storage::Memory.new,
          store: Shrine::Storage::Memory.new
        }
      end

      Shrine.plugin :activerecord
      Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
      Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
      Shrine.plugin :determine_mime_type, analyzer: :marcel
    CODE
  else
    file "app/components/foo.rb", <<-CODE
      require "shrine"
      require "shrine/storage/file_system"
      require "shrine/storage/memory"
      require "shrine/storage/s3"
      require "image_processing/vips"

      if Rails.env.test?
        Shrine.storages = {
          cache: Shrine::Storage::Memory.new,
          store: Shrine::Storage::Memory.new
        }
      elsif Rails.env.development? # use file system for development server
        Shrine.storages = {
          cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"), # temporary
          store: Shrine::Storage::FileSystem.new("public", prefix: "uploads"),       # permanent
        }
      elsif ENV['SECRET_KEY_BASE_DUMMY']
        Shrine.storages = {
          cache: Shrine::Storage::Memory.new,
          store: Shrine::Storage::Memory.new
        }
      else
        Shrine.storages = {
          cache: Shrine::Storage::S3.new(prefix: "cache", **s3_options),
          store: Shrine::Storage::S3.new(**s3_options)
        }
      end

      Shrine.plugin :activerecord
      Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
      Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
      Shrine.plugin :determine_mime_type, analyzer: :marcel
    CODE
  end
end

if yes?("Would you like to integrate with inertia?")
  # TODO
  run "bundle add inertia_rails --skip-install", verbose: false
  run "bundle add inertia_rails-contrib --skip-install", verbose: false
  run "bundle add js_from_routes --skip-install", verbose: false
  run "bundle add types_from_serializers --skip-install", verbose: false
  say "Running bundle install"
  run "bundle install", verbose: false
  rails_command "generate inertia:install"
else
  say "Running bundle install"
  run "bundle install", verbose: false
end

say "Installing config gem"
rails_command "generate config:install"
say "Installing devise"
rails_command "generate devise:install"
