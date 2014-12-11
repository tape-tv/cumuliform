require 'spec_helper'

describe "CloudFormation Intrinsic functions" do
  let(:template) { Cumuliform::Template.new }

  context "verified cross-references" do
    it "provides a convenience function for verifying a logical id ref without using the Ref intrinsic function" do
      template.parameter("Param") { {k: "v"} }
      template.resource("Res") do
        {
          Referent: xref("Param")
        }
      end

      output = template.to_hash
      expect(output["Resources"]["Res"]).to eq({Referent: "Param"})
    end

    it "complains about a missing Logical ID at generation time" do
      template.resource("Res") do
        {
          Referent: ref("Param")
        }
      end

      expect { template.to_hash }.to raise_error(
        Cumuliform::Error::NoSuchLogicalId
      )
    end
  end

  context "references" do
    it "provides a convenience function for the Ref intrinsic function" do
      template.parameter("Param") { {k: "v"} }
      template.resource("Res") do
        {
          Referent: ref("Param")
        }
      end

      output = template.to_hash
      expect(output["Resources"]["Res"]).to eq({Referent: {"Ref" => "Param"}})
    end

    it "complains about a missing Logical ID at generation time" do
      template.resource("Res") do
        {
          Referent: ref("Param")
        }
      end

      expect { template.to_hash }.to raise_error(
        Cumuliform::Error::NoSuchLogicalId
      )
    end

    it "supports the use of AWS:: pseudo parameters" do
      template.resource("Res") do
        {
          Referent: ref("AWS::AccountId")
        }
      end

      expect { template.to_hash }.not_to raise_error
    end
  end

  describe "Fn::* functions" do
    context "Fn::FindInMap" do
      it "generates the correct output" do
        template.mapping("AMap") { {"level-1" => {"level-2" => "Value"}} }

        template.resource "Res" do
          {k: fn.find_in_map("AMap", "level-1", "level-2")}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::FindInMap" => ["AMap", "level-1", "level-2"]}
            }
          }
        )
      end

      it "errors on bad mapping logical id" do
        template.resource "Res" do
          {k: fn.find_in_map("AMap", "level-1", "level-2")}
        end

        expect { template.to_hash }.to raise_error(
          Cumuliform::Error::NoSuchLogicalId
        )
      end
    end
  end
end
