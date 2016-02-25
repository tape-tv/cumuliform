require_relative './import-fragments-base.rb'

Cumuliform.template do
  import FragmentBaseTemplate

  def_fragment(:instance_type) do |opts|
    parameter 'InstanceType' do
      {
        Description: 'InstanceType',
        Type: 'String',
        Default: opts[:type],
        AllowedValues: ['m3.medium', 'm4.large', 'm4.xlarge']
      }
    end
  end

  fragment(:instance_type, type: 'm3.medium')
end
