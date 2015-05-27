# Cumuliform

[![Build Status](https://travis-ci.org/tape-tv/cumuliform.svg?branch=master)](https://travis-ci.org/tape-tv/cumuliform) [![Code Climate](https://codeclimate.com/github/tape-tv/cumuliform/badges/gpa.svg)](https://codeclimate.com/github/tape-tv/cumuliform) [![Test Coverage](https://codeclimate.com/github/tape-tv/cumuliform/badges/coverage.svg)](https://codeclimate.com/github/tape-tv/cumuliform/coverage)

Amazon’s [CloudFormation AWS service][cf] provides a way to describe infrastructure stacks using a JSON template. We love CloudFormation, and use it a lot, but the JSON templates are hard to write and read, it's very hard to reuse things shared between stacks, and it's very easy to make simple typos which are not discovered until minutes into stack creation when things fail for seemingly crazy reasons.

[cf]: http://aws.amazon.com/cloudformation/

Cumuliform is a tool to help eliminate as many sources of reference errors as possible, and to allow easier reuse of template parts between stacks. It provides a simple DSL that generates reliably valid JSON and enforces referential integrity through convenience wrappers around the common points where CloudFormation expects references between resources. provides.

Cumuliform has been extracted from ops and deployment code at [tape.tv][tape]

[tape]: https://www.tape.tv/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cumuliform'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cumuliform

## Usage

TODO: Add comprehensive examples.

The simplest way to use Cumuliform is to define a template `.rb` file like this:

```ruby
Cumuliform.template do
  resource "MyInstance" do
    {
      Type: 'AWS::EC2::Instance',
      ...
    }
  end
end
```

and add a Rake file task like this:

```ruby
rule ".cform" => ".rb" do |t|
  template = eval(File.read(t.source), binding, t.source)
  File.open(t.name, 'w:utf-8') { |f| f.write(template.to_json) }
end
```

The task reads and `eval`s the source `template.rb` template, the template returns a new `Cumuliform::Template` instance, and then calls its `to_json` method and writes the result to `template.cform`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/tape-tv/cumuliform/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
