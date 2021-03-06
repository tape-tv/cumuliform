# Cumuliform

[![Gem Version](https://badge.fury.io/rb/cumuliform.svg)](http://badge.fury.io/rb/cumuliform) [![Build Status](https://travis-ci.org/tape-tv/cumuliform.svg?branch=master)](https://travis-ci.org/tape-tv/cumuliform) [![Code Climate](https://codeclimate.com/github/tape-tv/cumuliform/badges/gpa.svg)](https://codeclimate.com/github/tape-tv/cumuliform) [![Test Coverage](https://codeclimate.com/github/tape-tv/cumuliform/badges/coverage.svg)](https://codeclimate.com/github/tape-tv/cumuliform/coverage) [![Documentation](https://inch-ci.org/github/tape-tv/cumuliform.svg?branch=master)]

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

Cumuliform was originally extracted from ops and deployment code at tape.tv

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

More detailed examples are below the section on Rake...

# Rake tasks and the Command Line runner

Cumuliform provides a very simple command-line runner to turn a `.rb` template
into JSON:

```sh
$ cumuliform /path/to/input_template.rb /path/to/output_template.json
```

It also provides a Rake task generator to create a Rake `rule` task to turn
`x.rb` into `x.cform`:

```ruby
require 'cumuliform/rake_task'

Cumuliform::RakeTask.rule '.cform' => '.rb'
```

To transform `filename.rb` into `filename.cform`:

```sh
$ rake filename.cform
```

If you haven't used Rake's `rule` tasks before, this [Rake rules article from
Avdi Grimm][rules] is a good place to start.

[rules]: http://devblog.avdi.org/2014/04/23/rake-part-3-rules/

You'll almost certainly want something more sophisticated than that. Here's an
example that declares the standard rule and adds a `FileList` to list the
targets (CloudFormation templates you want to generate) based on your sources
(Ruby Cumuliform template files). `rake cform` will transform all `.rb` files
in the same dir as your `Rakefile` into the corresponding `.cform` files:

```ruby
require 'cumuliform/rake_task'

Cumuliform::RakeTask.rule '.cform' => '.rb'

TARGETS = Rake::FileList['*.rb'].ext('.cform')

task :cform => TARGETS
```

# Examples

## Simple top-level object declarations

This example declares one of each of the top level objects Cumuliform
supports. More details can be found in CloudFormation's [Template
Anatomy documentation][cf-ta].

[cf-ta]: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html

```ruby
Cumuliform.template do
  # See http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html
  parameter 'AMI' do
    {
      Description: 'The AMI id for our template (defaults to the stock Ubuntu 14.04 image in eu-central-1)',
      Type: 'String',
      Default: 'ami-accff2b1'
    }
  end

  # See http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html
  mapping 'RegionAMI' do
    {
      'eu-central-1' => {
        'hvm' => 'ami-accff2b1',
        'pv' => 'ami-b6cff2ab'
      },
      'eu-west-1' => {
        'hvm' => 'ami-47a23a30',
        'pv' => 'ami-5da23a2a'
      }
    }
  end

  # See http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html
  condition 'Ireland' do
    fn.equals(ref('AWS::Region'), 'eu-west-1')
  end

  # See http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html
  resource 'PrimaryInstance' do
    {
      Type: 'AWS::EC2::Instance',
      Properties: {
        ImageId: ref('AMI'),
        InstanceType: 'm3.medium'
      }
    }
  end

  # See http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html
  output 'PrimaryInstanceID' do
    {
      Value: ref('PrimaryInstance')
    }
  end
end
```

The generated template is:

```json
{
  "Parameters": {
    "AMI": {
      "Description": "The AMI id for our template (defaults to the stock Ubuntu 14.04 image in eu-central-1)",
      "Type": "String",
      "Default": "ami-accff2b1"
    }
  },
  "Mappings": {
    "RegionAMI": {
      "eu-central-1": {
        "hvm": "ami-accff2b1",
        "pv": "ami-b6cff2ab"
      },
      "eu-west-1": {
        "hvm": "ami-47a23a30",
        "pv": "ami-5da23a2a"
      }
    }
  },
  "Conditions": {
    "Ireland": {
      "Fn::Equals": [
        {
          "Ref": "AWS::Region"
        },
        "eu-west-1"
      ]
    }
  },
  "Resources": {
    "PrimaryInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": {
          "Ref": "AMI"
        },
        "InstanceType": "m3.medium"
      }
    }
  },
  "Outputs": {
    "PrimaryInstanceID": {
      "Value": {
        "Ref": "PrimaryInstance"
      }
    }
  }
}
```

Note that the optional `AWSTemplateFormatVersion`, and `Metadata` sections are
*not* currently supported.

Here's a trivial template that specifies a `Transform` top-level value (e.g. for [AWS SAM][])

[AWS SAM]: https://github.com/awslabs/serverless-application-model

```ruby
Cumuliform.template do
  transform 'AWS::Serverless-2016-10-31'
  resource 'MyFunction' do
    {
      Type: 'AWS::Serverless::Function'
    }
  end
end
```

And the result:

```json
{
  "Transform": "AWS::Serverless-2016-10-31",
  "Resources": {
    "MyFunction": {
      "Type": "AWS::Serverless::Function"
    }
  }
}
```

## Intrinsic functions

Cumuliform provides convenience wrappers for all the intrinsic functions. See
CloudFormation's [Intrinsic Function documentation][cf-if].

[cf-if]: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html

```ruby
Cumuliform.template do
  mapping 'RegionAMI' do
    {
      'eu-central-1' => {
        'hvm' => 'ami-accff2b1',
        'pv' => 'ami-b6cff2ab'
      },
      'eu-west-1' => {
        'hvm' => 'ami-47a23a30',
        'pv' => 'ami-5da23a2a'
      }
    }
  end

  parameter 'VirtualizationMethod' do
    {
      Type: 'String',
      Default: 'hvm'
    }
  end

  resource 'PrimaryInstance' do
    {
      Type: 'AWS::EC2::Instance',
      Properties: {
        ImageId: fn.find_in_map('RegionAMI', ref('AWS::Region'),
                                ref('VirtualizationMethod')),
        InstanceType: 'm3.medium',
        AvailabilityZone: fn.select(0, fn.get_azs),
        UserData: fn.base64(
          fn.join('', [
            "#!/bin/bash -xe\n",
            "apt-get update\n",
            "apt-get -y install python-pip python-docutils\n",
            "pip install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n",
            "/usr/local/bin/cfn-init",
            " --region ", ref("AWS::Region"),
            " --stack ", ref("AWS::StackId"),
            " --resource #{xref('PrimaryInstance')}",
            " --configsets db"
          ])
        ),
        Metadata: {
          'AWS::CloudFormation::Init' => {
            configSets: { db: ['install'] },
            install: {
              commands: {
                '01-apt' => {
                  command: 'apt-get install postgresql postgresql-contrib'
                },
                '02-db' => {
                  command: 'sudo -u postgres createdb the-db'
                }
              }
            }
          }
        }
      }
    }
  end

  resource 'SiteDNS' do
    {
      Type: "AWS::Route53::RecordSet",
      Properties: {
        HostedZoneName: 'my-zone.example.org',
        Name: 'service.my-zone.example.org',
        ResourceRecords: [fn.get_att(xref('LoadBalancer'), 'DNSName')],
        TTL: '900',
        Type: 'CNAME'
      }
    }
  end

  resource 'LoadBalancer' do
    {
      Type: 'AWS::ElasticLoadBalancing::LoadBalancer',
      Properties: {
        AvailabilityZones: [fn.select(0, fn.get_azs)],
        Listeners: [
          {
            InstancePort: 5432,
            Protocol: 'TCP'
          }
        ],
        Instances: [ref('PrimaryInstance')]
      }
    }
  end
end
```

The generated template is:

```json
{
  "Parameters": {
    "VirtualizationMethod": {
      "Type": "String",
      "Default": "hvm"
    }
  },
  "Mappings": {
    "RegionAMI": {
      "eu-central-1": {
        "hvm": "ami-accff2b1",
        "pv": "ami-b6cff2ab"
      },
      "eu-west-1": {
        "hvm": "ami-47a23a30",
        "pv": "ami-5da23a2a"
      }
    }
  },
  "Resources": {
    "PrimaryInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": {
          "Fn::FindInMap": [
            "RegionAMI",
            {
              "Ref": "AWS::Region"
            },
            {
              "Ref": "VirtualizationMethod"
            }
          ]
        },
        "InstanceType": "m3.medium",
        "AvailabilityZone": {
          "Fn::Select": [
            "0",
            {
              "Fn::GetAZs": ""
            }
          ]
        },
        "UserData": {
          "Fn::Base64": {
            "Fn::Join": [
              "",
              [
                "#!/bin/bash -xe\n",
                "apt-get update\n",
                "apt-get -y install python-pip python-docutils\n",
                "pip install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz\n",
                "/usr/local/bin/cfn-init",
                " --region ",
                {
                  "Ref": "AWS::Region"
                },
                " --stack ",
                {
                  "Ref": "AWS::StackId"
                },
                " --resource PrimaryInstance",
                " --configsets db"
              ]
            ]
          }
        },
        "Metadata": {
          "AWS::CloudFormation::Init": {
            "configSets": {
              "db": [
                "install"
              ]
            },
            "install": {
              "commands": {
                "01-apt": {
                  "command": "apt-get install postgresql postgresql-contrib"
                },
                "02-db": {
                  "command": "sudo -u postgres createdb the-db"
                }
              }
            }
          }
        }
      }
    },
    "SiteDNS": {
      "Type": "AWS::Route53::RecordSet",
      "Properties": {
        "HostedZoneName": "my-zone.example.org",
        "Name": "service.my-zone.example.org",
        "ResourceRecords": [
          {
            "Fn::GetAtt": [
              "LoadBalancer",
              "DNSName"
            ]
          }
        ],
        "TTL": "900",
        "Type": "CNAME"
      }
    },
    "LoadBalancer": {
      "Type": "AWS::ElasticLoadBalancing::LoadBalancer",
      "Properties": {
        "AvailabilityZones": [
          {
            "Fn::Select": [
              "0",
              {
                "Fn::GetAZs": ""
              }
            ]
          }
        ],
        "Listeners": [
          {
            "InstancePort": 5432,
            "Protocol": "TCP"
          }
        ],
        "Instances": [
          {
            "Ref": "PrimaryInstance"
          }
        ]
      }
    }
  }
}
```

## Condition functions

Cumuliform provides convenience wrappers for all the Condition-related intrinsic functions. See
CloudFormation's [Condition Function documentation][cf-cif].

[cf-cif]: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html

```ruby
Cumuliform.template do
  parameter 'AMI' do
    {
      Type: 'String',
      Default: 'ami-12345678'
    }
  end

  parameter 'UtilAMI' do
    {
      Type: 'String',
      Default: 'ami-abcdef12'
    }
  end

  parameter 'InstanceType' do
    {
      Description: "The instance type",
      Type: 'String',
      Default: 'c4.large'
    }
  end

  condition 'InEU' do
    fn.or(
      fn.equals('eu-central-1', ref('AWS::Region')),
      fn.equals('eu-west-1', ref('AWS::Region'))
    )
  end

  condition 'UtilBox' do
    fn.and(
      fn.equals('m4.large', ref('InstanceType')),
      {"Condition": xref('InEU')}
    )
  end

  condition 'WebBox' do
    fn.not(ref('UtilBox'))
  end

  resource 'WebInstance' do
    {
      Type: "AWS::EC2::Instance",
      Condition: xref('WebBox'),
      Properties: {
        ImageId: ref('AMI'),
        InstanceType: ref('InstanceType')
      }
    }
  end

  resource 'UtilInstance' do
    {
      Type: "AWS::EC2::Instance",
      Condition: xref('UtilBox'),
      Properties: {
        ImageId: ref('UtilAMI'),
        InstanceType: ref('InstanceType')
      }
    }
  end
end
```

The generated template is:

```json
{
  "Parameters": {
    "AMI": {
      "Type": "String",
      "Default": "ami-12345678"
    },
    "UtilAMI": {
      "Type": "String",
      "Default": "ami-abcdef12"
    },
    "InstanceType": {
      "Description": "The instance type",
      "Type": "String",
      "Default": "c4.large"
    }
  },
  "Conditions": {
    "InEU": {
      "Fn::Or": [
        {
          "Fn::Equals": [
            "eu-central-1",
            {
              "Ref": "AWS::Region"
            }
          ]
        },
        {
          "Fn::Equals": [
            "eu-west-1",
            {
              "Ref": "AWS::Region"
            }
          ]
        }
      ]
    },
    "UtilBox": {
      "Fn::And": [
        {
          "Fn::Equals": [
            "m4.large",
            {
              "Ref": "InstanceType"
            }
          ]
        },
        {
          "Condition": "InEU"
        }
      ]
    },
    "WebBox": {
      "Fn::Not": [
        {
          "Ref": "UtilBox"
        }
      ]
    }
  },
  "Resources": {
    "WebInstance": {
      "Type": "AWS::EC2::Instance",
      "Condition": "WebBox",
      "Properties": {
        "ImageId": {
          "Ref": "AMI"
        },
        "InstanceType": {
          "Ref": "InstanceType"
        }
      }
    },
    "UtilInstance": {
      "Type": "AWS::EC2::Instance",
      "Condition": "UtilBox",
      "Properties": {
        "ImageId": {
          "Ref": "UtilAMI"
        },
        "InstanceType": {
          "Ref": "InstanceType"
        }
      }
    }
  }
}
```

### xref
Quite often you'll need to use a Resource, Condition, or Parameter Logical ID
outside of a `{ "Ref" => "LogicalID" }`. Because Logical IDs are one of the
things we *can* check at evaluation time, we provide a function that simply
takes a Logical ID, checks it, then returns it. If the Logical ID isn't there
then it explodes with a `Cumuliform::Error::NoSuchLogicalId`.

```ruby
resource "Resource" do
  {
    Type: "AWS::EC2::Instance",
    Condition: xref("TheCondition")
  }
end
```

## Fragments
You'll often want to use a collection of resources several times in a template, and it can be pretty verbose and tedious. Cumuliform offers reusable fragments to allow you to reuse similar template chunks.

You define them with `def_fragment()` and use them with `fragment()`. You pass a name and a block to `def_fragment`. You call `fragment()` with the name of a fragment and an optional hash of options to pass to the fragment block. The fragment block is called and its return value output into the template.

Here's an example:

```ruby
Cumuliform.template do
  parameter 'AMI' do
    {
      Description: 'The AMI id for our template (defaults to the stock Ubuntu 14.04 image in eu-central-1)',
      Type: 'String',
      Default: 'ami-accff2b1'
    }
  end

  def_fragment(:instance) do |opts|
    resource opts[:logical_id] do
      {
        Type: 'AWS::EC2::Instance',
        Properties: {
          ImageId: ref('AMI'),
          InstanceType: opts[:instance_type]
        }
      }
    end
  end

  fragment(:instance, logical_id: 'LittleInstance', instance_type: 't2.micro')
  fragment(:instance, logical_id: 'BigInstance', instance_type: 'c4.xlarge')
end
```

And the output:

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
    "LittleInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": {
          "Ref": "AMI"
        },
        "InstanceType": "t2.micro"
      }
    },
    "BigInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": {
          "Ref": "AMI"
        },
        "InstanceType": "c4.xlarge"
      }
    }
  }
}
```

## Importing other templates
If you want to share complete resources, or fragments, between different
templates then you can import one template into another. All the imported
template's resources will be available to you, and you can override template
parts (i.e. a parameter) or even fragments simply be defining them again in the
importing template.

To import a template, you simply `require` it as you would any other ruby file,
and then use Cumuliform's `import` method to import it.

This is easier to explain with an example. Take this very simple example,
defining a single `AWS::EC2::Instance` in a `resource`, and a `parameter` that
controls the AMI it uses:

```ruby
BaseTemplate = Cumuliform.template do
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

It generates the following JSON (as expected):

```
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

Say we to change the default AMI parameter but reuse everything else. We can
import that template and redefine the `parameter`:

```ruby
require_relative './import-base.rb'

Cumuliform.template do
  import BaseTemplate

  parameter 'AMI' do
    {
      Description: 'A different AMI',
      Type: 'String',
      Default: 'ami-DIFFERENT'
    }
  end
end
```

That produces the following JSON:

```
{
  "Parameters": {
    "AMI": {
      "Description": "A different AMI",
      "Type": "String",
      "Default": "ami-DIFFERENT"
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

There are a couple of very important points to note: First, we have to
`require` the base template (exactly as you require any ruby file). Second, we
have to assign the result of calling `Cumuliform.template` to a constant so
that it is available once we've required the file.

In the importing template, once we have `require`d the base template, we pass
the constant containing the base template to the `import` DSL method.

## Importing fragments
Fragments defined in a template are also available when imported. You can
override fragments in the importing template as you would override a resource.

Here's a base template that defines several fragments (shown with the JSON it
generates).

```ruby
FragmentBaseTemplate = Cumuliform.template do
  def_fragment(:ami_param) do |opts|
    parameter 'AMI' do
      {
        Description: 'AMI id',
        Type: 'String',
        Default: opts[:ami_id]
      }
    end
  end

  def_fragment(:instance_type) do |opts|
    parameter 'InstanceType' do
      {
        Description: 'InstanceType',
        Type: 'String',
        Default: opts[:type],
        AllowedValues: ['t2.small', 't2.medium', 't2.large']
      }
    end
  end

  def_fragment(:instance) do |opts|
    resource 'MyInstance' do
      {
        Type: 'AWS::EC2::Instance',
        Properties: {
          ImageId: ref('AMI'),
          InstanceType: ref('InstanceType')
        }
      }
    end
  end

  fragment(:ami_param, ami_id: 'ami-accff2b1')
  fragment(:instance_type, type: 't2.medium')
  fragment(:instance)
end
```

```
{
  "Parameters": {
    "AMI": {
      "Description": "AMI id",
      "Type": "String",
      "Default": "ami-accff2b1"
    },
    "InstanceType": {
      "Description": "InstanceType",
      "Type": "String",
      "Default": "m4.medium",
      "AllowedValues": [
        "t2.small",
        "t2.medium",
        "t2.large"
      ]
    }
  },
  "Resources": {
    "MyInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": {
          "Ref": "AMI"
        },
        "InstanceType": {
          "Ref": "InstanceType"
        }
      }
    }
  }
}
```

An importing template can use, or override, the fragments exactly as with any
other resource:

```ruby
require_relative './import-fragments-base.rb'

Cumuliform.template do
  import FragmentBaseTemplate

  def_fragment(:instance_type) do |opts|
    parameter 'InstanceType' do
      {
        Description: 'InstanceType',
        Type: 'String',
        Default: opts[:type],
        AllowedValues: ['m3.medium', 'm4.large', 'm4.xlarge']
      }
    end
  end

  fragment(:instance_type, type: 'm3.medium')
end
```

```
{
  "Parameters": {
    "AMI": {
      "Description": "AMI id",
      "Type": "String",
      "Default": "ami-accff2b1"
    },
    "InstanceType": {
      "Description": "InstanceType",
      "Type": "String",
      "Default": "m3.medium",
      "AllowedValues": [
        "m3.medium",
        "m4.large",
        "m4.xlarge"
      ]
    }
  },
  "Resources": {
    "MyInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": {
          "Ref": "AMI"
        },
        "InstanceType": {
          "Ref": "InstanceType"
        }
      }
    }
  }
}
```

We redefined the fragment so the allowed values for instance type allowed the
instance type we wanted to use. (Using the fragments in the base template is a
bit weird, and not really recommended - it's included here to warn you...)


## Assigning templates to constants, namespaces, and processing
The `Cumuliform.template` method returns a template object directly. So, to
make a template that can be imported into another template you need to assign
it to a variable or constant.

If you want to be able to directly process your base templates (instead of only
using them by importing them into another template), then you also need to make
sure your file returns the template when it's run. The runner works by
`class_eval`ing your template file as a string and expecting that the result of
that call will be an instance of `Cumuliform::Template`. If you use namespaces
for your template objects (as you might if you have several base templates)
then you need to be careful of that: the last line in your template must be
something that returns the template. If you're nesting within modules, then the
call to `module` will return `nil`, not the template. Instead, return the
template as the last line:

```
module Stacks
  Base = Cumuliform.template do
    ...
  end
end

Stacks::Base
```

## Helpers
Because templates are actually instances, not classes or modules, you can't
simply `include` a mixin module. Cumuliform provides a `helpers` DSL method
that allows you pass in modules, or block containing helper methods, that will
be made available to the template:

```ruby
Cumuliform.template do
  helpers do
    def ami
      'ami-accff2b1'
    end
  end

  resource 'MyInstance' do
    {
      Type: 'AWS::EC2::Instance',
      Properties: {
        ImageId: ami,
        InstanceType: 'm3.medium'
      }
    }
  end
end
```

Which evaluates to:

```
{
  "Resources": {
    "MyInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-accff2b1",
        "InstanceType": "m3.medium"
      }
    }
  }
}
```

Or using a module:

```ruby
module AmiHelper
  def ami
    'ami-accff2b1'
  end
end

Cumuliform.template do
  helpers AmiHelper

  resource 'MyInstance' do
    {
      Type: 'AWS::EC2::Instance',
      Properties: {
        ImageId: ami,
        InstanceType: 'm3.medium'
      }
    }
  end
end
```

Which also evaluates to:

```
{
  "Resources": {
    "MyInstance": {
      "Type": "AWS::EC2::Instance",
      "Properties": {
        "ImageId": "ami-accff2b1",
        "InstanceType": "m3.medium"
      }
    }
  }
}
```

Helper methods are not able to access any methods on the template (like
`resource`), they're really for wrapping complex external calls (for example, a
class that fetches an API token you need to use in your template).

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
