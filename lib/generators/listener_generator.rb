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
        pending "add some examples to (or delete) \#{__FILE__}"
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
