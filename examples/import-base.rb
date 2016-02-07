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
