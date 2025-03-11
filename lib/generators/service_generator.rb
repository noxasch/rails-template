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
