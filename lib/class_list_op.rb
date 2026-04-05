# frozen_string_literal: true

require_relative "class_list/version"
require_relative "class_list/errors"
require_relative "class_list/tokenizer"
require_relative "class_list/resolver"
require_relative "class_list/list"

module ClassList
  class << self
    def normalize(value)
      Tokenizer.call(value)
    end

    def tokens(base = nil, **operations)
      Resolver.call(base, **operations)
    end

    def resolve(base = nil, **operations)
      tokens(base, **operations).join(" ")
    end

    def call(base = nil, **operations)
      resolve(base, **operations)
    end

    def list(base = nil)
      List.new(base)
    end
  end
end
