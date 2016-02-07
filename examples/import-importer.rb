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
