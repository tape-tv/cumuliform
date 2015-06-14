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
