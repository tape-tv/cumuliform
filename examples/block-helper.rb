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
