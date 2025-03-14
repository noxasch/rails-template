# frozen_string_literal: true

module MutationMatchers
  RSpec::Matchers.define :require_input do |sym|
    raise RSpec::Matchers::Mutations::InvalidArgumentError if sym.nil?

    match do |_subject|
      described_class.new.input_filters.required_inputs.include?(sym)
    end
  end

  RSpec::Matchers.define :accept_input do |sym|
    raise RSpec::Matchers::Mutations::InvalidArgumentError if sym.nil?

    match do |_subject|
      described_class.new.input_filters.optional_inputs.include?(sym)
    end
  end
end
