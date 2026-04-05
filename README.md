# class_list_op

`class_list_op` is a rendering-agnostic Ruby gem for deterministic CSS class token composition.

It does not know anything about Rails, ViewComponent, Phlex, Tailwind, or HTML rendering. It only:

- normalizes class input
- applies class operations
- returns tokens or a resolved string

Public namespace:

```ruby
ClassList
```

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add class_list_op
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install class_list_op
```

## Usage

```ruby
require "class_list_op"

ClassList.normalize(["flex gap-4", ["mb-2", nil, ""]])
# => ["flex", "gap-4", "mb-2"]

ClassList.resolve("flex gap-4", add: "mb-4")
# => "flex gap-4 mb-4"

ClassList.resolve("flex gap-4", remove: "gap-4")
# => "flex"

ClassList.resolve("flex gap-4", replace: "mb-4")
# => "mb-4"

ClassList.call("flex gap-4", add: :hidden)
# => "flex gap-4 hidden"

list = ClassList.list("flex gap-4")
updated = list.remove("gap-4").add("mb-4")

list.to_s
# => "flex gap-4"

updated.tokens
# => ["flex", "mb-4"]

defaults = { class: "flex gap-4", id: "main" }
overrides = { class: { add: "mb-4", remove: "gap-4" } }

ClassList.resolve_attributes(defaults, overrides)
# => { class: "flex mb-4", id: "main" }

button = ClassList.variants(
  base: {
    container: "font-medium whitespace-nowrap inline-flex items-center"
  },
  defaults: {
    size: :md,
    tone: :default
  },
  dimensions: {
    size: {
      xs: { container: "px-1.5 py-1 rounded-md text-xs" },
      md: { container: "px-3 py-2 rounded-lg text-sm" }
    },
    tone: {
      default: { container: "text-white bg-blue-600 hover:bg-blue-700" },
      red: { container: "text-white bg-red-600 hover:bg-red-700" }
    }
  }
)

button.attributes(:container, tone: :red, class: { add: "w-full" })
# => { class: "font-medium whitespace-nowrap inline-flex items-center px-3 py-2 rounded-lg text-sm text-white bg-red-600 hover:bg-red-700 w-full" }
```

### Supported inputs

`ClassList.normalize` and operation values accept:

- `String`
- `Array`
- `Symbol`
- `nil`

Normalization rules:

- `nil` is ignored
- strings are split by whitespace
- arrays are flattened recursively
- empty strings are ignored
- unsupported types raise `ClassList::InvalidInputError`

### Operations

Supported operations:

- `add`
- `remove`
- `replace`

Rules:

- `replace` cannot be combined with `add` or `remove`
- operations are applied in this order: `base -> remove -> add -> uniq`
- deduplication is stable and keeps the first occurrence

Example for component builders:

```ruby
defaults = "cols w-full md:flex md:flex-row md:space-x-4"

ClassList.resolve(defaults, add: "mb-4")
# => "cols w-full md:flex md:flex-row md:space-x-4 mb-4"

ClassList.resolve(defaults, remove: "md:space-x-4", add: "md:space-x-6")
# => "cols w-full md:flex md:flex-row md:space-x-6"
```

### Attribute adapter

`ClassList.resolve_attributes` is a thin adapter for component-style attribute hashes.

- non-`class` attributes use normal hash merge semantics
- `class: "..."` still fully overrides defaults
- `class: { add:, remove:, replace: }` applies class operations against the default class value

`ClassList.merge_attributes` remains available as a compatibility alias.

Arbre-style example:

```ruby
class Cols < BaseComponent
  builder_method :cols

  def build(attributes = {})
    attributes = { breakpoint: :md }.merge(attributes)

    direction = attributes.delete(:direction) || :row
    space = attributes.delete(:space) || 4
    breakpoint = attributes.delete(:breakpoint)

    defaults = { class: cols_classes(direction:, space:, breakpoint:) }

    super(ClassList.resolve_attributes(defaults, attributes))
  end

  def columns
    children.grep(Col)
  end

  private

  def cols_classes(direction:, space:, breakpoint:)
    [
      "cols w-full",
      "#{breakpoint}:flex",
      direction_variant(direction, space:, breakpoint:)
    ]
  end

  def direction_variant(direction, space:, breakpoint:)
    space_axis = direction.to_s.include?("row") ? "x" : "y"

    [
      "#{breakpoint}:flex-#{direction}",
      "#{breakpoint}:space-#{space_axis}-#{space}"
    ]
  end
end

cols class: { add: "mb-4", remove: "md:space-x-4" } do
  # ...
end
```

### Variants

`ClassList::Variants` automates the repetitive `base + selected variants + class operations` assembly without introducing a DSL.

- config is just a Ruby hash and can come from YAML
- all Tailwind classes stay as literal strings for extractor safety
- dimensions are selected by key and merged in order
- any non-dimension options are treated as final attribute overrides

```ruby
button = ClassList.variants(
  base: {
    container: "font-medium whitespace-nowrap text-center inline-flex items-center cursor-pointer",
    icon: "shrink-0"
  },
  defaults: {
    size: :md,
    tone: :default
  },
  dimensions: {
    size: {
      xs: {
        container: "px-1.5 py-1 rounded-md text-xs",
        icon: "size-3"
      },
      md: {
        container: "px-3 py-2 rounded-lg text-sm",
        icon: "size-4"
      }
    },
    tone: {
      default: {
        container: "text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-800"
      },
      red: {
        container: "text-white bg-red-600 hover:bg-red-700 focus:ring-red-800"
      }
    }
  }
)

button.attributes(:container, size: :xs, tone: :red)
# => { class: "font-medium whitespace-nowrap text-center inline-flex items-center cursor-pointer px-1.5 py-1 rounded-md text-xs text-white bg-red-600 hover:bg-red-700 focus:ring-red-800" }

button.attributes(:container, tone: :red, class: { add: "w-full" })
# => { class: "... w-full" }

button.attributes(:icon, size: :xs)
# => { class: "shrink-0 size-3" }
```

`Col` can follow the same pattern:

```ruby
class Col < BaseComponent
  builder_method :col

  def build(size_or_options = "1/2", options = {})
    options = { breakpoint: :md }.merge(options)
    breakpoint = options.delete(:breakpoint)

    defaults = { class: col_classes(size_or_options, breakpoint:) }

    super(ClassList.merge_attributes(defaults, options))
  end

  private

  def col_classes(size_or_options, breakpoint:)
    case size_or_options
    when Hash
      size_or_options.map { |bp, size| "#{bp}:w-#{size}" }
    else
      ["#{breakpoint}:w-#{size_or_options}"]
    end
  end
end

col "1/2", class: { add: "mb-4" }
col({ md: "1/2", xl: "1/3" }, class: { add: "self-start" })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alexander-fokin/class_list_op. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/alexander-fokin/class_list_op/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `class_list_op` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/alexander-fokin/class_list_op/blob/main/CODE_OF_CONDUCT.md).
