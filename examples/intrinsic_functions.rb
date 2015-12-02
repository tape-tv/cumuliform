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
