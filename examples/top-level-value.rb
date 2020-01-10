Cumuliform.template do
  transform 'AWS::Serverless-2016-10-31'
  resource 'MyFunction' do
    {
      Type: 'AWS::Serverless::Function'
    }
  end
end
