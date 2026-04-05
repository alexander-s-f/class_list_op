# frozen_string_literal: true

module ClassList
  class List
    attr_reader :tokens

    def initialize(base = nil)
      @tokens = ClassList.normalize(base).freeze
    end

    def add(value)
      self.class.from_tokens(Resolver.call(@tokens, add: value))
    end

    def remove(value)
      self.class.from_tokens(Resolver.call(@tokens, remove: value))
    end

    def replace(value)
      self.class.from_tokens(Resolver.call(@tokens, replace: value))
    end

    def to_s
      @tokens.join(" ")
    end

    def inspect
      %(#<#{self.class.name} #{to_s.inspect}>)
    end

    def self.from_tokens(tokens)
      instance = allocate
      instance.instance_variable_set(:@tokens, tokens.freeze)
      instance
    end
  end
end
