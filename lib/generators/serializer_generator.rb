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
