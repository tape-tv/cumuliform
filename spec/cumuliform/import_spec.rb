require 'spec_helper'

describe "Template importing" do
  context "basic items" do
    it "are made available in the importing template" do
      base_template = Cumuliform.template {
        resource("Eg") { "Value" }
      }

      importing_template = Cumuliform.template {
        import base_template
      }

      expect(importing_template.to_hash).to eq({"Resources" => {"Eg" => "Value"}})
    end

    it "can be overridden in the importing template" do
      base_template = Cumuliform.template {
        resource("Eg") { "Value" }
      }

      importing_template = Cumuliform.template {
        import base_template
        resource("Eg") { "Other" }
      }

      expect(importing_template.to_hash).to eq({"Resources" => {"Eg" => "Other"}})
    end
  end
end
