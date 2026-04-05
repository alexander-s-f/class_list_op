# frozen_string_literal: true

module ClassList
  module AttributeMerger
    module_function

    def call(base = nil, overrides = nil, class_key: :class)
      base_attributes = normalize_attributes(base)
      override_attributes = normalize_attributes(overrides)

      return base_attributes.merge(override_attributes) unless override_attributes.key?(class_key)

      merged_attributes = base_attributes.merge(override_attributes)
      merged_attributes[class_key] = resolve_class_value(base_attributes[class_key], override_attributes[class_key])
      merged_attributes
    end

    def normalize_attributes(value)
      case value
      when nil
        {}
      when Hash
        value.dup
      else
        raise InvalidInputError, "unsupported attribute input: #{value.class}"
      end
    end

    def resolve_class_value(base_value, override_value)
      return override_value unless override_value.is_a?(Hash)

      operations = override_value.each_with_object({}) do |(key, value), result|
        result[key.to_sym] = value
      end

      ClassList.resolve(base_value, **operations)
    end
  end
end
