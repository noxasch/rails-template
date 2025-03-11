class MutationGenerator < Rails::Generators::NamedBase
  check_class_collision suffix: "Mutation"
  desc "This generator creates an mutation file inside app/mutations"

  def create_mutation_file
    create_file "app/mutations/#{file_path}_mutation.rb", <<~RUBY
      class #{class_name}Mutation < ApplicationMutation
        required do
        end

        optional do
        end

        protected

        def execute; end

        def validate; end
      end
    RUBY

    create_file "spec/mutations/#{file_path}_mutation_spec.rb", <<~RUBY
      require 'rails_helper'

      RSpec.describe #{class_name}Mutation, type: :mutation do
        pending "add some examples to (or delete) #{__FILE__}"
      end
    RUBY
  end
end
