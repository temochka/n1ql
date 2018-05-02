# N1QL Parser & Compiler for Ruby

[![Build Status](https://travis-ci.org/temochka/n1ql.svg?branch=master)](https://travis-ci.org/temochka/n1ql)

This library can parse N1QL queries and produce the AST format
expected by [CouchBase Lite Core](https://github.com/couchbase/couchbase-lite-core) as JSON.

## Installation

**This library is not available via Rubygems.**
If you want to try it out for any reason, add this line to your application's Gemfile:

```ruby
gem 'n1ql', github: 'temochka/n1ql'
```

And then execute:

    $ bundle

## Usage

Create a query object:

``` ruby
require 'n1ql'

query = N1ql::Query.new('SELECT name FROM users')

# => #<N1ql::Query:0x00007fb76786d870 @text="SELECT DISTINCT name FROM users" ...
```

Compile to N1QL AST:

``` ruby
query.compile

# => "{\"WHAT\":[[\".\",\"name\"]],\"DISTINCT\":true,\"FROM\":[{\"as\":\"users\"}]}"
```

Access column titles via `N1ql::Query#titles`:

``` ruby
query.titles
# => ["name"]
```

Specify placeholders to pass arguments:

``` ruby
query = N1ql::Query.new('SELECT name FROM users WHERE name=?name?')
query.compile(name: 'Artem')

# => "{\"WHAT\":[[\".\",\"name\"]],\"FROM\":[{\"as\":\"users\"}],\"WHERE\":[\"=\",[\".\",\"name\"],\"Artem\"]}"
```

See [query_spec.rb](spec/n1ql/query_spec.rb) for additional examples.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/temochka/n1ql.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
