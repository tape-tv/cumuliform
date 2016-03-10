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
