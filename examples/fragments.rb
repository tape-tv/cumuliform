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
