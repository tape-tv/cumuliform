require 'spec_helper'
require 'stringio'
require 'tmpdir'
require 'pathname'
require 'cumuliform/runner'

RSpec::Matchers.define :io_contents do |str|
  match { |actual| actual.read == str }
end

RSpec.describe Cumuliform::Runner do
  let(:simple_input) {
    <<-EOF
Cumuliform.template do
  resource 'MyInstance' do
    {
      Type: 'AWS::EC2::Instance',
      Properties: {
        ImageId: 'ami-accff2b1',
        InstanceType: 'm3.medium'
      }
    }
  end
end
    EOF
  }
  context "the core processing" do
    it "returns a Cumuliform::Template" do
      input = StringIO.new(simple_input)
      result = Cumuliform::Runner.process_io(input)
      expect(result).to be_instance_of(Cumuliform::Template)
    end

    it "doesn't pollute the main object with constants" do
      input = StringIO.new <<-EOF
        GUBBINS = "thing"
      EOF

      Cumuliform::Runner.process_io(input)
      expect { GUBBINS }.to raise_error
    end
  end

  context "invoking with file path args" do
    it "correctly invokes the core" do
      template = Cumuliform::Runner.process_io(StringIO.new(simple_input))

      Dir.mktmpdir do |dir|
        input_path = File.expand_path('input.rb', dir)
        File.write(input_path, simple_input)
        output_path = File.expand_path('output.cform', dir)

        Cumuliform::Runner.process(input_path, output_path)

        expect(File.exist?(output_path))
        expect(File.read(output_path)).to eq(template.to_json)
      end
    end
  end
end
