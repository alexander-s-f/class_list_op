# frozen_string_literal: true

module ClassList
  Error = Class.new(StandardError)
  InvalidInputError = Class.new(Error)
  InvalidOperationError = Class.new(Error)
  InvalidVariantError = Class.new(Error)
end
