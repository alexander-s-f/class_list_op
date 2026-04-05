# frozen_string_literal: true

module ClassList
  module Resolver
    ALLOWED_KEYS = %i[add remove replace].freeze

    module_function

    def call(base = nil, **operations)
      validate_operations!(operations)

      return uniq_tokens(Tokenizer.call(operations[:replace])) if operations.key?(:replace)

      tokens = Tokenizer.call(base)
      tokens = apply_remove(tokens, operations[:remove])
      tokens = apply_add(tokens, operations[:add])

      uniq_tokens(tokens)
    end

    def validate_operations!(operations)
      unknown_keys = operations.keys - ALLOWED_KEYS

      unless unknown_keys.empty?
        raise InvalidOperationError, "unknown operations: #{unknown_keys.join(', ')}"
      end

      return if valid_replace_combination?(operations)

      raise InvalidOperationError, "replace cannot be combined with add/remove"
    end

    def valid_replace_combination?(operations)
      return true unless operations.key?(:replace)

      (operations.keys & %i[add remove]).empty?
    end

    def apply_remove(tokens, value)
      remove_tokens = Tokenizer.call(value)
      return tokens if remove_tokens.empty?

      tokens.reject { |token| remove_tokens.include?(token) }
    end

    def apply_add(tokens, value)
      tokens + Tokenizer.call(value)
    end

    def uniq_tokens(tokens)
      tokens.each_with_object([]) do |token, result|
        result << token unless result.include?(token)
      end
    end
  end
end
