require 'spec_helper'

module Cumuliform
  describe "Template sections" do
    let(:section) { Section.new("Name", []) }

    it "returns its name" do
      expect(section.name).to eq("Name")
    end

    it "items are added in a hashlike way" do
      section["Hello"] = "Value"
      expect(section["Hello"]).to eq("Value")
    end

    context "imports" do
      let(:imported) {
        imported = double('template')
        allow(imported).to receive(:get_section).with('Name') {
          imported_section
        }
        imported
      }
      let(:imports) { [imported] }
      let(:imported_section) { Section.new("Name", []) }
      let(:section) { Section.new("Name", imports) }

      it "can be pulled from an imported template" do
        imported_section["Hello"] = "Value"

        expect(section["Hello"]).to eq("Value")
      end

      it "can be overridden" do
        imported_section["Hello"] = "Value"
        section["Hello"] = "Other Value"

        expect(section["Hello"]).to eq("Other Value")
      end
    end

    context "verifying lookups" do
      it "can look up a logical id" do
        section["Hello"] = "Value"

        expect(section.member?("Hello")).to be(true)
      end

      it "can look up a logical id in an imported template" do
        imported = double('template')
        imported_section = Section.new("Name", [])
        allow(imported).to receive(:get_section).with('Name') {
          imported_section
        }
        imported_section["Hello"] = "Value"

        section = Section.new("Name", [imported])

        expect(section.member?("Hello")).to be(true)
      end
    end
  end
end
