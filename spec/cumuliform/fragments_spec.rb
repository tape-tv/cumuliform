require 'spec_helper'

describe "Template fragments" do
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
