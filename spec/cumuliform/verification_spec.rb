require 'spec_helper'

module Cumuliform
  describe "Verifying logical IDs" do
    let(:template) { Template.new }

    it "can report the presence of an ID in the template" do
      template.resource("Test") { {Id: "Test"} }

      expect(template.has_logical_id?("Test")).to be(true)
    end

    it "can report the absence of an ID in the template" do
      expect(template.has_logical_id?("Test")).to be(false)
    end

    it "can verify the presence of an ID" do
      template.resource("Test") { {Id: "Test"} }

      expect(template.verify_logical_id!("Test")).to be(true)
    end

    it "explodes when verifying an absent ID" do
      expect { template.verify_logical_id!("Test") }.to raise_error(
        Error::NoSuchLogicalId
      )
    end

    context "by section" do
      SECTIONS.each do |section_name, method|
        it "can verify the presence of a #{method}" do
          template.send(method, "Test") { {Id: "Test"} }

          expect(template.send(:"verify_#{method}_logical_id!", "Test")).to be(true)
        end

        it "explodes when verifying an absent #{method}" do
          expect {
            template.send(:"verify_#{method}_logical_id!", "Test")
          }.to raise_error(
            Error.const_get("NoSuchLogicalIdIn#{section_name}")
          )
        end
      end
    end
  end
end
