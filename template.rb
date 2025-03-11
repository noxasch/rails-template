NODE = 'pnpm'.freeze

# TODO assert minimu node version
# modularize into function

# set source path
source_paths.unshift(File.dirname(__FILE__))

say "Adding necessary gems"

# development test gem
gem_group :development, :test do
  gem "bullet"
  gem "rspec-rails"
  gem "factory_bot_rails", require: false
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "js_from_routes"
  gem "types_from_serializers"
end

# development gem
gem_group :development do
  gem "annotate"
  gem "database_consistency", require: false
end

# test gem
gem_group :test do
  gem "rspec-json_expectations", require: false
  gem "rspec_junit_formatter", require: false
  gem "shoulda-matchers", require: false
  gem "simplecov", require: false
  gem "simplecov-cobertura", require: false
  gem "ruby-prof", require: false
  gem "test-prof", require: false
  gem "wisper-rspec", require: false
end

# gem
gem "config"
gem "devise"
gem "devise_invitable"
gem "action_policy"
gem "friendly_id"
gem "hash_to_struct"
gem "mutations"
gem "oj_serializers"
gem "pagy"
gem "phony_rails"

if yes?("Would you like use sidekiq? (y/n)")
  gem "sidekiq"
end

if yes?("Would you like to use shrine for file attachment? (y/n)")
  gem "image_processing"
  gem "marcel"
  gem "ruby-vips"
  gem "shrine"

  if yes?("Would you like to use s3 or s3 compatible service? (y/n)")
    gem "aws-sdk-s3"

    file "config/initializers/shrine.rb", <<-CODE
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
    file "config/initializers/shrine.rb", <<-CODE
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

# NOTE: need to run before bundle install
copy_file "app/serializers/application_serializer.rb", "app/serializers/application_serializer.rb"
copy_file "app/mutations/application_mutation.rb", "app/mutations/application_mutation.rb"
copy_file "app/services/application_service.rb", "app/services/application_service.rb"

if yes?("Would you like to integrate with inertia? (y/n)")
  # TODO
  gem "inertia_rails"

  insert_into_file "app/controllers/application_controller.rb", after: /^class ApplicationController.*\n/ do
    <<-RUBY
    include Pagy::Backend

    before_action :set_csrf_cookie

    rescue_from ActionController::InvalidAuthenticityToken, with: :inertia_page_expired_error

    inertia_share flash: -> { flash.to_hash }

    def inertia_page_expired_error
      redirect_back fallback_location: '/', notice: 'The page expired, please try again.'
    end

    def request_authenticity_tokens
      super << request.headers['HTTP_X_XSRF_TOKEN']
    end

    private

    def set_csrf_cookie
      cookies['XSRF-TOKEN'] = {
        value: form_authenticity_token,
        same_site: 'Strict'
      }
    end
    RUBY
  end


  say "Running bundle install"
  run "bundle install", verbose: false
  rails_command "generate inertia:install"
  # run "bin/rails generate inertia:install"
else
  insert_into_file "app/controllers/application_controller.rb", after: /^class ApplicationController.*\n/ do
    <<-RUBY
  include Pagy::Backend

  before_action :set_csrf_cookie

  rescue_from ActionController::InvalidAuthenticityToken, with: :inertia_page_expired_error

  inertia_share flash: -> { flash.to_hash }

  def inertia_page_expired_error
    redirect_back fallback_location: "/", notice: "The page expired, please try again."
  end

  def request_authenticity_tokens
    super << request.headers["HTTP_X_XSRF_TOKEN"]
  end

  private

  def set_csrf_cookie
    cookies["XSRF-TOKEN"] = {
      value: form_authenticity_token,
      same_site: "Strict"
    }
  end
    RUBY
  end

  say "Running bundle install"
  run "bundle install", verbose: false
end

say "Installing config gem"
run "bin/rails generate config:install"
say "Installing devise"
run "bin/rails generate devise:install"

source = File.expand_path(find_in_source_paths("config/initializers/config.rb"))
render = File.open(source) { |input| input.binmode.read }
prepend_to_file 'config/initializers/config.rb', render

copy_file "config/initializers/js_from_routes.rb", "config/initializers/js_from_routes.rb"

copy_file "lib/generators/listener_generator.rb", "lib/generators/listener_generator.rb"
copy_file "lib/generators/mutation_generator.rb", "lib/generators/mutation_generator.rb"
copy_file "lib/generators/serializer_generator.rb", "lib/generators/serializer_generator.rb"
copy_file "lib/generators/service_generator.rb", "lib/generators/service_generator.rb"

file "app/listeners/application_listener.rb", <<-RUBY  
class ApplicationListener
end
RUBY

say "Adding node packages"
if NODE == 'pnpm'
  run "pnpm add @js-from-routes/axios", verbose: false
  run "pnpm add -D eslint @types/node @antfu/eslint-config vite-plugin-full-reload", verbose: false
else
  run "npm install @js-from-routes/axios", verbose: false
  run "npm install -D eslint @types/node @antfu/eslint-config vite-plugin-full-reload", verbose: false
end

say "you can specify gem version by using pessmize by running:"
say "gem install pessmize"
say "pessimize"
