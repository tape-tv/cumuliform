require 'spec_helper'

describe Cumuliform::Template do
  context "definition" do
    context "logical IDs" do
      it "does not allow duplicate logical IDs to be used within resources" do
        subject.resource("Hello") { {k: "v"} }

        expect { subject.resource("Hello") { {k: 0} } }.to raise_error(
          Cumuliform::Error::DuplicateLogicalID
        )
      end

      it "does not allow duplicate logical IDs to be used across sections" do
        subject.resource("Hello") { {k: "v"} }

        expect { subject.parameter("Hello") { {k: 1} } }.to raise_error(
          Cumuliform::Error::DuplicateLogicalID
        )
      end
    end

    context "Items" do
      it "takes the return value of a block passed in as the value of the item" do
        subject.resource "Hello" do
          {k: "v"}
        end

        output = subject.to_hash
        expect(output["Resources"]).to eq({"Hello" => {k: "v"}})
      end

      it "complains about items defined without a block" do
        subject.resource("Hello")

        expect { subject.to_hash }.to raise_error(
          Cumuliform::Error::EmptyItem
        )
      end

      it "does not allow empty items to be defined" do
        subject.resource("Hello") do
          {}
        end

        expect { subject.to_hash }.to raise_error(
          Cumuliform::Error::EmptyItem
        )
      end
    end

  end

  context "output" do
    it "correctly generates top-level keys for sections" do
      subject.parameter("Param") { {k: "v"} }
      subject.mapping("Map") { {k: "v"} }
      subject.condition("Cond") { {k: "v"} }
      subject.resource("Res") { {k: "v"} }
      subject.output("Out") { {k: "v"} }

      output = subject.to_hash

      expect(output.keys).to eq(%w{ Parameters Mappings Conditions Resources Outputs })
    end

    it "doesn't generate keys for empty sections" do
      subject.resource("Res") { {k: "v"} }
      subject.output("Out") { {k: "v"} }

      output = subject.to_hash

      expect(output.keys).to eq(%w{ Resources Outputs })
    end

    it "complains if there are no resources" do
      expect { subject.to_hash }.to raise_error(
        Cumuliform::Error::NoResourcesDefined
      )
    end
  end

  context "helpers" do
    it "includes modules with helper functions as instance methods correctly" do
      h = Module.new do
        def da_helper
          resource("Helped") { {k: "v"} }
        end
      end

      subject.helpers(h)
      subject.da_helper

      expect { subject.resource("Helped") }.to raise_error(
        Cumuliform::Error::DuplicateLogicalID
      )
    end

    it "turns blocks into modules and makes them helpers too" do
      subject.helpers do
        def da_helper
          resource("Helped") { {k: "v"} }
        end
      end

      subject.da_helper

      expect { subject.resource("Helped") }.to raise_error(
        Cumuliform::Error::DuplicateLogicalID
      )
    end
  end
end
