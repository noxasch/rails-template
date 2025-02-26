
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

if yes?("Would you like use sidekiq? (y/n)")
  run "bundle add sidekiq --skip-install", verbose: false
end

if yes?("Would you like to use shrine for file attachment? (y/n)")
  run "bundle add image_processing --skip-install", verbose: false
  run "bundle add marcel --skip-install", verbose: false
  run "bundle add ruby-vips --skip-install", verbose: false
  run "bundle add shrine --skip-install", verbose: false

  if yes?("Would you like to use s3 or s3 compatible service? (y/n)")
    run "bundle add aws-sdk-s3 --skip-install", verbose: false

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

file "app/serializers/application_serializer.rb", <<-CODE  
  class ApplicationSerializer < Oj::Serializer
    transform_keys :camelize
    sort_attributes_by :name
  end
CODE

if yes?("Would you like to integrate with inertia? (y/n)")
  # TODO
  run "bundle add inertia_rails --skip-install", verbose: false
  run "bundle add inertia_rails-contrib --skip-install", verbose: false
  run "bundle add js_from_routes --skip-install", verbose: false
  run "bundle add types_from_serializers --skip-install", verbose: false

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

    RUBY
  end

  say "Running bundle install"
  run "bundle install", verbose: false
end

say "Installing config gem"
run "bin/rails generate config:install"
say "Installing devise"
run "bin/rails generate devise:install"

file "app/services/application_service.rb", <<-CODE
  #
  # Any service class that inherit this base class can be call as in the example
  # and return the same outcome format
  #
  # ideally we want to return result containing the processed object
  #   in case of error, we want to return result/outcome object containing the error and success: false
  #   and should not catch expected error outside of service class
  #   - similar approach to mutation gem which act as service class in a controller
  #
  # @example:
  #   `MyService.call(args)`
  #
  # @note: see existing class that inherit `ApplicationService` for example
  #
  class ApplicationService
    def self.call(*, &)
      new(*, &).call
    end

    def call
      raise NotImplementedError
    end

    def logger
      @logger ||= ServiceLog
    end
  end
CODE

file "app/mutations/application_mutation.rb", <<-CODE  
  class ApplicationMutation < Mutations::Command
    private

    def add_model_errors(obj)
      obj.errors.each do |err|
        add_error(err.attribute.to_sym, err.type.to_sym, "#\{err.message}.")
      end
    end
  end
CODE

file "app/listeners/application_listener.rb", <<-CODE  
  class ApplicationListener
  end
CODE

file "lib/generators/mutation_generator.rb", <<-CODE
  class MutationGenerator < Rails::Generators::NamedBase
    check_class_collision suffix: 'Mutation'
    desc 'This generator creates an mutation file inside app/mutations'

    def create_mutation_file
      create_file "app/mutations/#\{file_path}_mutation.rb", <<~RUBY
        class #\{class_name}Mutation < ApplicationMutation
          required do
          end

          optional do
          end

          protected

          def execute; end

          def validate; end
        end
      RUBY

      create_file "spec/mutations/#\{file_path}_mutation_spec.rb", <<~RUBY
        require 'rails_helper'

        RSpec.describe #\{class_name}Mutation, type: :mutation do
          pending "add some examples to (or delete) \#\{__FILE__}"
        end
      RUBY
    end
  end
CODE

file "lib/generators/service_generator.rb", <<-CODE  
  class ServiceGenerator < Rails::Generators::NamedBase
    check_class_collision suffix: 'Service'
    desc 'This generator creates an service class file with its companion spec file'

    def create_service_file
      create_file "app/services/#\{file_path}_service.rb", <<~RUBY
        class #\{class_name}Service < #\{parent_class_name.classify}
          def self.call(*, &)
            new(*, &).call
          end

          def initialize(args1, args2, args = {})
            @args1 = args1
            @args2 = args2
            @args = args
          end

          def call; end
        end
      RUBY

      create_file "spec/services/#\{file_path\}_service_spec.rb", <<~RUBY
        require 'rails_helper'

        RSpec.describe #\{class_name\}Service, type: :service do
          pending "add some examples to (or delete) \#\{__FILE__}"
        end
      RUBY
    end

    private

    def parent_class_name
      'ApplicationService'
    end
  end
CODE

file "lib/generators/serializer_generator.rb", <<-CODE
  class SerializerGenerator < Rails::Generators::NamedBase
    check_class_collision suffix: 'Serializer'
    desc 'This generator creates an Serializer file inside app/serializers'
    class_option :parent, type: :string, desc: 'The parent class for the generated serializer'

    def create_serializer_file
      create_file "app/serializers/#\{file_path}_serializer.rb", <<~RUBY
        class #\{class_name}Serializer < #\{parent_class_name.classify}
          object_as :object

          attributes :id
        end
      RUBY

      create_file "spec/serializers/#\{file_path}_serializer_spec.rb", <<~RUBY
        require 'rails_helper'

        RSpec.describe #\{class_name}Serializer, type: :serializer do
          pending "add some examples to (or delete) \#\{__FILE__}"
        end
      RUBY
    end

    private

    def parent
      options[:parent]
    end

    def parent_class_name
      parent || 'ApplicationSerializer'
    end
  end
CODE

file "lib/generators/listener_generator.rb", <<-CODE
  # frozen_string_literal: true

  class ListenerGenerator < Rails::Generators::NamedBase
    check_class_collision suffix: 'Listener'
    desc 'This generator creates an Listener file inside app/listeners'
    class_option :parent, type: :string, desc: 'The parent class for the generated listener'

    def create_mutation_file
      create_file "app/listeners/#\{file_path}_listener.rb", <<~RUBY
        class #\{class_name}Listener < #\{parent_class_name.classify}
        end
      RUBY

      create_file "spec/listeners/#\{file_path}_listener_spec.rb", <<~RUBY
        require 'rails_helper'

        RSpec.describe #\{class_name}Listener, type: :serializer do
          pending "add some examples to (or delete) \#\{__FILE__}"
        end
      RUBY
    end

    private

    def parent
      options[:parent]
    end

    def parent_class_name
      parent || 'ApplicationListener'
    end
  end
CODE
