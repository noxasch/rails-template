# frozen_string_literal: true

if Rails.env.development?
  TypesFromSerializers.config do |config|
    config.base_serializers = [ "ApplicationSerializer" ]

    config.skip_serializer_if = lambda { |serializer|
      serializer.to_s.downcase.include?("based")
    }
  end
end
