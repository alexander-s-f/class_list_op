# frozen_string_literal: true

module ClassList
  module Tokenizer
    module_function

    def call(value)
      case value
      when nil
        []
      when String
        value.split(/\s+/).reject(&:empty?)
      when Symbol
        [value.to_s]
      when Array
        value.flat_map { |item| call(item) }
      else
        raise InvalidInputError, "unsupported class input: #{value.class}"
      end
    end
  end
end
