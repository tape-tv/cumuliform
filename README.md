# Cumuliform

[![Build Status](https://travis-ci.org/tape-tv/cumuliform.svg?branch=master)](https://travis-ci.org/tape-tv/cumuliform) [![Code Climate](https://codeclimate.com/github/tape-tv/cumuliform/badges/gpa.svg)](https://codeclimate.com/github/tape-tv/cumuliform) [![Test Coverage](https://codeclimate.com/github/tape-tv/cumuliform/badges/coverage.svg)](https://codeclimate.com/github/tape-tv/cumuliform/coverage)

Amazon’s [CloudFormation AWS service][cf] provides a way to describe
infrastructure stacks using a JSON template. We love CloudFormation, and use it
a lot, but the JSON templates are hard to write and read, it's very hard to
reuse things shared between stacks, and it's very easy to make simple typos
which are not discovered until minutes into stack creation when things fail for
seemingly crazy reasons.

[cf]: http://aws.amazon.com/cloudformation/

Cumuliform is a tool to help eliminate as many sources of reference errors as
possible, and to allow easier reuse of template parts between stacks. It
provides a simple DSL that generates reliably valid JSON and enforces
referential integrity through convenience wrappers around the common points
where CloudFormation expects references between resources. provides.

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

# Getting started

You’ll probably want to familiarise yourself with the [CloudFormation getting
started guide][cf-get-started] if you haven’t already.

[cf-get-started]: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/GettingStarted.html

To quickly recap the key points for template authors:

1. A template is a JSON file containing a single Object (`{}`)
2. The template object is split into specific sections through top-level
   properties (resources, parameters, mappings, and outputs).
3. The things we’re actually interested in are object children of those
   top-level objects, and the keys (‘logical IDs’ in CloudFormation terms) must
   be unique across each of the four sections.
4. Resources, parameters, and the like are just JSON Objects.
5. CloudFormation provides what it calls ‘Intrinsic Functions’, e.g. `Fn::Ref`
   to define links and dependencies between your resources.
6. Because a template is just a JSON object, it’s very easy to accidentally
   define a resource or parameter with the same logical id more than once, which
   results in a last-one-wins situation where the object defined latest in the
   file will obliterate the previously defined one.

Cumuliform provides DSL methods to define objects in each of the four sections,
helps catch any duplicate logical IDs and provides wrappers for CloudFormation’s
Intrinsic Functions that enforce referential integrity *before* you upload your
template and start creating a stack with it.

## The simplest possible template

Let’s define a very simple template consisting of one resource and one parameter

```ruby
Cumuliform.template do
  parameter 'AMI' do
    {
      Description: 'The AMI id for our template (defaults to the stock Ubuntu 14.04 image in eu-central-1)',
      Type: 'String',
      Default: 'ami-accff2b1'
    }
  end

  resource 'MyInstance' do
    {
      Type: 'AWS::EC2::Instance',
      Properties: {
        ImageId: ref('AMI'),
        InstanceType: 'm3.medium'
      }
    }
  end
end
```

Processing the ruby source with cumuliform's command line runner gives us this JSON template:

```sh
$ cumuliform simplest.rb simplest.cform
```

```json
{
  "Parameters": {
    "AMI": {
      "Description": "The AMI id for our template (defaults to the stock Ubuntu 14.04 image in eu-central-1)",
      "Type": "String",
      "Default": "ami-accff2b1"
    }
  },
  "Resources": {
    "MyInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": {
          "Ref": "AMI"
        },
        "InstanceType": "m3.medium"
      }
    }
  }
}
```

# Rake tasks and the Command Line runner

Cumuliform provides a very simple command-line runner to turn a `.rb` template
into JSON:

```sh $ cumuliform /path/to/input_template.rb /path/to/output_template.json ```

It also provides a Rake task generator to create a Rake `rule` task to turn
`x.rb` into `x.cform`:

```
ruby require 'cumuliform/rake_task'

Cumuliform::RakeTask.rule '.cform' => '.rb'
```

To transform `filename.rb` into `filename.cform`:

```
sh $ rake filename.cform
```

If you haven't used Rake's `rule` tasks before, this [Rake rules article from
Avdi Grimm][rules] is a good place to start.

[rules]: http://devblog.avdi.org/2014/04/23/rake-part-3-rules/

You'll almost certainly want something more sophisticated than that. Here's an
example that declares the standard rule and adds a `FileList` to list the
targets (CloudFormation templates you want to generate) based on your sources
(Ruby Cumuliform template files). `rake cform` will transform all `.rb` files
in the same dir as your `Rakefile` into the corresponding `.cform` files:

```
ruby require 'cumuliform/rake_task'

Cumuliform::RakeTask.rule '.cform' => '.rb'

TARGETS = Rake::FileList['*.rb'].ext('.cform')

task :cform => TARGETS
```

# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release` to create a git tag for the version, push git
commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/tape-tv/cumuliform/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
