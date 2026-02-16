# KYAML

Encode Ruby objects as KYAML — a strict, flow-style YAML subset designed to avoid YAML's ambiguity pitfalls.

## Installation

Ruby >= 3.3 supported.

Add to your Gemfile:

```ruby
gem "kyaml-ruby", github: "djbender/kyaml-ruby"
```

## Usage

```ruby
require "kyaml"

KYAML.dump("hello")
# => "---\n\"hello\"\n"

KYAML.dump({name: "Alice", age: 30})
# => "---\nname: \"Alice\",\nage: 30,\n"

KYAML.dump([{id: 1}, {id: 2}])
# => "---\n[{id: 1,}, {id: 2,}]\n"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

| Tool             | Purpose                             |
| ---------------- | ----------------------------------- |
| `bin/setup`      | Install dependencies                |
| `bin/rake`       | Run specs + linter (CI default)     |
| `bin/rspec`      | Run tests                           |
| `bin/standardrb` | Lint / autofix with `--fix`         |
| `bin/console`    | IRB session with KYAML loaded       |

To install this gem onto your local machine, run `bin/rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/djbender/kyaml-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/djbender/kyaml-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the KYAML project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/djbender/kyaml-ruby/blob/main/CODE_OF_CONDUCT.md).
