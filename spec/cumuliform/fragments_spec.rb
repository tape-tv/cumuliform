require 'spec_helper'

describe "Template fragments" do
  let(:template) { Cumuliform::Template.new }

  context "definition" do
    it "allows a fragment to be defined" do
      template.fragment :frag do
        {key: "value"}
      end

      expect(template.fragments[:frag].call).to eq({key: "value"})
    end
  end

  context "inclusion" do
    it "allows a fragment to be included" do
      template.fragment :frag do
        {key: "value"}
      end

      template.resource("Ohai") do
        fragment(:frag)
      end

      output = template.to_hash

      expect(output['Resources']['Ohai']).to eq({key: "value"})
    end

    it "correctly handles deferred execution like ref()" do
      template.fragment :frag do
        {key: ref("Param")}
      end

      template.parameter("Param") { "Value" }

      template.resource("Ohai") do
        fragment(:frag)
      end

      output = template.to_hash

      expect(output['Resources']['Ohai']).to eq({key: {"Ref" => "Param"}})
    end

    it "allows arguments to be passed to the block" do
      template.fragment :frag do |arg|
        {key: arg}
      end

      template.resource("Ohai") do
        fragment(:frag, "Val")
      end

      output = template.to_hash

      expect(output['Resources']['Ohai']).to eq({key: "Val"})
    end
  end

  context "housekeeping" do
    it "does not allow a fragment name collision" do
      template.fragment(:frag) { "Value" }

      expect { template.fragment(:frag) { "Other value" } }.to raise_error(
        Cumuliform::Error::FragmentAlreadyDefined
      )
    end

    it "does not allow a non-existent fragment to be included" do
      template.resource("Ohai") { fragment(:frag) }

      expect { template.to_hash }.to raise_error(
        Cumuliform::Error::FragmentNotFound
      )
    end
  end

  describe "Fragment arguments" do
    context "without explicit options declared" do
      it "works with no args passed" do
        template = Cumuliform.template {
          fragment(:ref) { "hey" }
          resource("Eg") do
            fragment(:ref)
          end
        }

        expect(template.to_hash).to eq({"Resources" => {"Eg" => "hey"}})
      end

      it "works with args passed" do
        template = Cumuliform.template {
          fragment(:ref) { "hey" }
          resource("Eg") do
            fragment(:ref, hello: "mum")
          end
        }

        expect(template.to_hash).to eq({"Resources" => {"Eg" => "hey"}})
      end
    end

    context "with explicit options declared" do
      it "works with no args passed" do
        template = Cumuliform.template {
          fragment(:ref) { |opts| "hey #{opts[:hello]}".strip }
          resource("Eg") do
            fragment(:ref)
          end
        }

        expect(template.to_hash).to eq({"Resources" => {"Eg" => "hey"}})
      end

      it "works with args passed" do
        template = Cumuliform.template {
          fragment(:ref) { |opts| "hey #{opts[:hello]}".strip }
          resource("Eg") do
            fragment(:ref, hello: "there")
          end
        }

        expect(template.to_hash).to eq({"Resources" => {"Eg" => "hey there"}})
      end
    end
  end
end
