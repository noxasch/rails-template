module NegateMatchers
  RSpec::Matchers.define_negated_matcher :not_change, :change
end
