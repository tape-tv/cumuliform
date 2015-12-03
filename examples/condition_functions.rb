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
