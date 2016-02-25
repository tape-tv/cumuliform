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
  fragment(:instance_type, type: 'm4.medium')
  fragment(:instance)
end
