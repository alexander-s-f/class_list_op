# frozen_string_literal: true

module ClassList
  class Variants
    CLASS_KEY = :class

    def initialize(config)
      @config = normalize_config(config)
    end

    def tokens(slot = :container, **options)
      ClassList.normalize(attributes(slot, **options)[CLASS_KEY])
    end

    def resolve(slot = :container, **options)
      attributes(slot, **options)[CLASS_KEY].to_s
    end

    def attributes(slot = :container, **options)
      slot_name = slot.to_sym
      dimension_names = config.fetch(:dimensions, {}).keys
      dimension_options = {}
      overrides = {}

      options.each do |key, value|
        normalized_key = key.to_sym

        if dimension_names.include?(normalized_key)
          dimension_options[normalized_key] = value
        else
          overrides[normalized_key] = value
        end
      end

      selections = config.fetch(:defaults, {}).merge(dimension_options)

      base_attributes = attributes_for_slot(config.fetch(:base, {}), slot_name)
      variant_attributes = selections.reduce(base_attributes) do |result, (dimension_name, option_name)|
        selected = config.fetch(:dimensions, {}).fetch(dimension_name).fetch(option_name.to_sym) do
          raise InvalidVariantError, "unknown option #{option_name.inspect} for dimension #{dimension_name.inspect}"
        end

        merge_variant_attributes(result, attributes_for_slot(selected, slot_name))
      end

      ClassList.merge_attributes(variant_attributes, normalize_attributes(overrides))
    end

    def slots(**options)
      slot_names = [
        config.fetch(:base, {}).keys,
        config.fetch(:dimensions, {}).values.flat_map(&:values).flat_map(&:keys)
      ].flatten.compact.uniq

      slot_names.each_with_object({}) do |slot_name, result|
        result[slot_name] = attributes(slot_name, **options)
      end
    end

    private

    attr_reader :config

    def normalize_config(value)
      unless value.is_a?(Hash)
        raise InvalidInputError, "unsupported variants config: #{value.class}"
      end

      deep_symbolize(value)
    end

    def deep_symbolize(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, nested_value), result|
          result[key.to_sym] = deep_symbolize(nested_value)
        end
      when Array
        value.map { |item| deep_symbolize(item) }
      else
        value
      end
    end

    def attributes_for_slot(source, slot_name)
      normalize_attributes(source[slot_name])
    end

    def normalize_attributes(value)
      case value
      when nil
        {}
      when String, Symbol, Array
        { CLASS_KEY => value }
      when Hash
        value.dup
      else
        raise InvalidInputError, "unsupported variant attributes: #{value.class}"
      end
    end

    def merge_variant_attributes(base_attributes, layer_attributes)
      merged = base_attributes.merge(layer_attributes)

      merged[CLASS_KEY] = ClassList.resolve(base_attributes[CLASS_KEY], add: layer_attributes[CLASS_KEY])
      merged
    end
  end
end
