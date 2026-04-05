# frozen_string_literal: true

require_relative "class_list/version"
require_relative "class_list/errors"
require_relative "class_list/tokenizer"
require_relative "class_list/resolver"
require_relative "class_list/list"
require_relative "class_list/attribute_merger"
require_relative "class_list/variants"

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

    def resolve_attributes(base = nil, overrides = nil, class_key: :class)
      AttributeMerger.call(base, overrides, class_key: class_key)
    end

    alias_method :merge_attributes, :resolve_attributes

    def variants(config)
      Variants.new(config)
    end
  end
end
