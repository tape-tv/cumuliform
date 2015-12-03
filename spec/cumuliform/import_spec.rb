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

    it "does NOT preserve the defining context when referring to fragments" do
      base_template = Cumuliform.template {
        def_fragment(:ref) { "Hello" }

        resource("Eg") do
          fragment(:ref)
        end
      }

      importing_template = Cumuliform.template {
        import base_template

        def_fragment(:ref) { "Value" }
      }

      expect(importing_template.to_hash).to eq({"Resources" => {"Eg" => "Value"}})
    end
  end

  context "verifying lookups" do
    it "can look up a logical id in an imported template" do
      base_template = Cumuliform.template {
        resource("Eg") { "Value" }
      }

      importing_template = Cumuliform.template {
        import base_template
      }

      expect(importing_template.has_logical_id?("Eg")).to be(true)
    end

    it "leaves xref() working exactly as expected" do
      base_template = Cumuliform.template {
        resource("Eg") { "Value" }
      }

      importing_template = Cumuliform.template {
        import base_template
      }

      expect(importing_template.xref("Eg")).to eq("Eg")
    end
  end

  context "fragments" do
    it "gives access to an imported fragment" do
      base_template = Cumuliform.template {
        def_fragment(:eg) {
          "Value"
        }
      }

      importing_template = Cumuliform.template {
        import base_template

        resource("Eg") do
          fragment(:eg)
        end
      }

      expect(importing_template.to_hash).to eq({"Resources" => {"Eg" => "Value"}})
    end

    it "finds imported fragments when other fragments are referred" do
      base_template = Cumuliform.template {
        def_fragment(:ref) { "hey" }
        def_fragment(:eg) {
          {k: fragment(:ref)}
        }
      }

      importing_template = Cumuliform.template {
        import base_template

        resource("Eg") do
          fragment(:eg)
        end
      }

      expect(importing_template.to_hash).to eq({"Resources" => {"Eg" => {k: "hey"}}})
    end

    it "does NOT preserve the defining context when fragments ref other fragments" do
      base_template = Cumuliform.template {
        def_fragment(:ref) { "hey" }
        def_fragment(:eg) {
          {k: fragment(:ref)}
        }
      }

      importing_template = Cumuliform.template {
        import base_template

        def_fragment(:ref) { "ho" }
        resource("Eg") do
          fragment(:eg)
        end
      }

      expect(importing_template.to_hash).to eq({"Resources" => {"Eg" => {k: "ho"}}})
    end
  end
end
