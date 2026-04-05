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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alexander-fokin/class_list_op. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/alexander-fokin/class_list_op/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `class_list_op` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/alexander-fokin/class_list_op/blob/main/CODE_OF_CONDUCT.md).
