# ActiveRecord::ReturningAttributes

ReturningAttributes provides a way to populate model attributes with database-backed default values or values set via database triggers when creating or updating single records without executing additional database queries.

#### Slightly Longer Description

When having database-backed default values (like `NOW()`) or values set via database triggers, we don't get to see them when creating or updating records in Rails. This is because when inserting records, the PostgreSQL `RETURNING` clause only states the `id` (or a different primary key) column, other columns are not returned back to Rails-land. Similar to inserts, updates don't get to see those values because there's no `RETURNING` clause involved at all.

Internally this library changes the `RETURNING` clause for inserts and adds it for updates so we don't have to reload records.

Caveats:

- PostgreSQL only
- Only tested in Rails 5.2.0
- Overrides ActiveRecord core code

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record-returning_attributes', github: 'tbuehlmann/active_record-returning_attributes'
```

And then execute:

```sh
$ bundle install
```

## Usage

Assume having a database-backed default value for the `uuid` column or a trigger that sets the value.

Before:

```ruby
class Project < ApplicationRecord
end

project = Project.create
project.uuid # => nil

project.reload
project.uuid # => '2b57df54-3768-45c6-ad10-aeec028e7735'
```

After:

```ruby
class Project < ApplicationRecord
  self.returning_attributes = [:uuid]
end

project = Project.create
project.uuid # => '2b57df54-3768-45c6-ad10-aeec028e7735'
```

By setting `self.returning_attributes`, ActiveRecord will request those columns via the `RETURNING` clause and populate the corresponding attributes in your model.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tbuehlmann/active_record-returning_attributes.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
