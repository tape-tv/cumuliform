$:.unshift(File.expand_path('../lib', __dir__))

require 'dsl'

describe Cumuliform::Template do
  context "definition" do
    it "does not allow duplicate logical IDs to be used within resources" do
      subject.resource "Hello", {}

      expect { subject.resource "Hello", {} }.to raise_error(
        Cumuliform::DuplicateLogicalIDError
      )
    end

    it "does not allow duplicate logical IDs to be used across sections" do
      subject.resource "Hello", {}

      expect { subject.parameter "Hello", {} }.to raise_error(
        Cumuliform::DuplicateLogicalIDError
      )

    end
  end

  context "output" do
    it "correctly generates top-level keys for sections" do
      subject.parameter "Param", {}
      subject.mapping "Map", {}
      subject.condition "Cond", {}
      subject.resource "Res", {}
      subject.output "Out", {}

      output = subject.to_hash

      expect(output.keys).to eq(%w{ Parameters Mappings Conditions Resources Outputs })
    end

    it "doesn't generate keys for empty sections" do
      subject.resource "Res", {}
      subject.output "Out", {}

      output = subject.to_hash

      expect(output.keys).to eq(%w{ Resources Outputs })
    end

    it "complains if there are not resources" do
      subject.mapping "Map", {}

      expect { subject.to_hash }.to raise_error(
        Cumuliform::NoResourcesDefinedError
      )
    end
  end
end
