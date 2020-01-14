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
    context "Condition functions" do
      context "Fn::Equals" do
        it "generates the correct output with arguments" do
          template.resource "Res" do
            {k: fn.equals("foo", "bar")}
          end

          expect(template.to_hash['Resources']).to eq(
            {
              "Res" => {
                k: {"Fn::Equals" => ["foo", "bar"]}
              }
            }
          )
        end
      end

      context "Fn::If" do
        it "checks conditions with if" do
          template.resource "Res" do
            {k: fn.if("condition", "true_value", "false_value")}
          end

          expect(template.to_hash['Resources']).to eq(
            {
              "Res" => {
                k: {"Fn::If" => ["condition", "true_value", "false_value"]}
              }
            }
          )
        end
      end

      context "Fn::And" do
        it "creates And Conditions with and" do
          template.resource("Res") { {Type: "Bogus"} }
          template.condition "Cond" do
            fn.and(
              {"Condition" => "AnotherCondition"},
              {"Condition" => "YACondition"}
            )
          end

          expect(template.to_hash['Conditions']).to eq({
            "Cond" => {
              "Fn::And" => [
                {"Condition" => "AnotherCondition"},
                {"Condition" => "YACondition"}
              ]
            }
          })
        end

        it "explodes given only one arg" do
          expect { template.fn.and({"Condition" => "Cond"}) }.to raise_error(ArgumentError)
        end

        it "explodes given more than 10 args" do
          expect { template.fn.and(
            {"Condition" => "Cond1"},
            {"Condition" => "Cond2"},
            {"Condition" => "Cond3"},
            {"Condition" => "Cond4"},
            {"Condition" => "Cond5"},
            {"Condition" => "Cond6"},
            {"Condition" => "Cond7"},
            {"Condition" => "Cond8"},
            {"Condition" => "Cond9"},
            {"Condition" => "Cond10"},
            {"Condition" => "Cond11"}
          ) }.to raise_error(ArgumentError)
        end

        it "10 args are fine" do
          expect { template.fn.and(
            {"Condition" => "Cond1"},
            {"Condition" => "Cond2"},
            {"Condition" => "Cond3"},
            {"Condition" => "Cond4"},
            {"Condition" => "Cond5"},
            {"Condition" => "Cond6"},
            {"Condition" => "Cond7"},
            {"Condition" => "Cond8"},
            {"Condition" => "Cond9"},
            {"Condition" => "Cond10"}
          ) }.not_to raise_error
        end
      end

      context "Fn::Or" do
        it "creates And Conditions with and" do
          template.resource("Res") { {Type: "Bogus"} }
          template.condition "Cond" do
            fn.or(
              {"Condition" => "AnotherCondition"},
              {"Condition" => "YACondition"}
            )
          end

          expect(template.to_hash['Conditions']).to eq({
            "Cond" => {
              "Fn::Or" => [
                {"Condition" => "AnotherCondition"},
                {"Condition" => "YACondition"}
              ]
            }
          })
        end

        it "explodes given only one arg" do
          expect { template.fn.or({"Condition" => "Cond"}) }.to raise_error(ArgumentError)
        end

        it "explodes given more than 10 args" do
          expect { template.fn.or(
            {"Condition" => "Cond1"},
            {"Condition" => "Cond2"},
            {"Condition" => "Cond3"},
            {"Condition" => "Cond4"},
            {"Condition" => "Cond5"},
            {"Condition" => "Cond6"},
            {"Condition" => "Cond7"},
            {"Condition" => "Cond8"},
            {"Condition" => "Cond9"},
            {"Condition" => "Cond10"},
            {"Condition" => "Cond11"}
          ) }.to raise_error(ArgumentError)
        end

        it "10 args are fine" do
          expect { template.fn.or(
            {"Condition" => "Cond1"},
            {"Condition" => "Cond2"},
            {"Condition" => "Cond3"},
            {"Condition" => "Cond4"},
            {"Condition" => "Cond5"},
            {"Condition" => "Cond6"},
            {"Condition" => "Cond7"},
            {"Condition" => "Cond8"},
            {"Condition" => "Cond9"},
            {"Condition" => "Cond10"}
          ) }.not_to raise_error
        end
      end

      context "Fn::Not" do
        it "creates Not Condition" do
          template.resource("Res") { {Type: "Bogus"} }
          template.condition "Cond" do
            fn.not(
              {"Condition" => "AnotherCondition"}
            )
          end

          expect(template.to_hash['Conditions']).to eq({
            "Cond" => {
              "Fn::Not" => [
                {"Condition" => "AnotherCondition"}
              ]
            }
          })
        end
      end
    end

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
          Cumuliform::Error::NoSuchLogicalIdInMappings
        )
      end

      it "errors on being given a non-mapping logical id" do
        template.parameter "NotAMap" do
          {k: "Value"}
        end
        template.resource "Res" do
          {k: fn.find_in_map("NotAMap", "level-1", "level-2")}
        end

        expect { template.to_hash }.to raise_error(
          Cumuliform::Error::NoSuchLogicalIdInMappings
        )
      end
    end

    context "Fn::GetAtt" do
      it "generates the correct output" do
        template.resource("R1") { {k: "Value"} }

        template.resource "Res" do
          {k: fn.get_att("R1", "SomeAttr")}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "R1" => {
              k: "Value"
            },
            "Res" => {
              k: {"Fn::GetAtt" => ["R1", "SomeAttr"]}
            }
          }
        )
      end

      it "errors on bad resource logical id" do
        template.resource "Res" do
          {k: fn.get_att("R1", "SomeAttr")}
        end

        expect { template.to_hash }.to raise_error(
          Cumuliform::Error::NoSuchLogicalIdInResources
        )
      end

      it "errors on being given a non-mapping logical id" do
        template.parameter "NotAResource" do
          {k: "Value"}
        end

        template.resource "Res" do
          {k: fn.get_att("NotAResource", "SomeAttr")}
        end

        expect { template.to_hash }.to raise_error(
          Cumuliform::Error::NoSuchLogicalIdInResources
        )
      end
    end

    context "Fn::Join" do
      it "generates the correct output" do
        template.resource "Res" do
          {k: fn.join("", ["one", "two"])}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Join" => ["", ["one", "two"]]}
            }
          }
        )
      end

      it "explodes if you don't hand it an array" do
        expect { template.fn.join("", "") }.to raise_error(ArgumentError)
      end
    end

    context "Fn::Base64" do
      it "generates the correct output" do
        template.resource "Res" do
          {k: fn.base64("string")}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Base64" => "string"}
            }
          }
        )
      end
    end

    context "Fn::GetAZs" do
      it "generates the correct output without arguments" do
        template.resource "Res" do
          {k: fn.get_azs}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::GetAZs" => ""}
            }
          }
        )
      end

      it "generates the correct output with an argument" do
        template.resource "Res" do
          {k: fn.get_azs("eu-central-1")}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::GetAZs" => "eu-central-1"}
            }
          }
        )
      end
    end

    context "Fn::Select" do
      it "generates the correct output" do
        template.resource "Res" do
          {k: fn.select(1, ["a", "b", "c"])}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Select" => ["1", ["a", "b", "c"]]}
            }
          }
        )
      end

      it "explodes if index is not an integer" do
        expect { template.fn.select("a", ["a"]) }.to raise_error(ArgumentError)
      end

      it "explodes if index is not a positive integer" do
        expect { template.fn.select(-1, ["a"]) }.to raise_error(ArgumentError)
      end

      it "explodes if array is an array literal and index is too large" do
        expect { template.fn.select(2, ["a"]) }.to raise_error(IndexError)
      end

      it "allows a Fn::Ref experession for index and doesn't check constraints" do
        template.resource "Res" do
          {k: fn.select({"Fn::Ref" => "SomeParameter"}, ["a", "b"])}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Select" => [{"Fn::Ref" => "SomeParameter"}, ["a", "b"]]}
            }
          }
        )
      end

      it "doesn't check lenth constraints on non-array-literal array args (e.g. ref())" do
        template.resource "Res" do
          {k: fn.select(2, {"Fn::Ref" => "SomeAttr"})}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Select" => ["2", {"Fn::Ref" => "SomeAttr"}]}
            }
          }
        )
      end
    end

    context "Fn::Cidr" do
      it "generates the correct output" do
        template.resource "Res" do
          {k: fn.cidr('192.168.0.0/24', 6, 5)}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Cidr" => ["192.168.0.0/24", 6, 5]}
            }
          }
        )
      end
    end

    context "Fn::ImportValue" do
      it "generates the correct output" do
        template.resource "Res" do
          {k: fn.import_value('OtherStackName')}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::ImportValue" => "OtherStackName"}
            }
          }
        )
      end
    end

    context "Fn::Split" do
      it "generates the correct output" do
        template.resource "Res" do
          {k: fn.split(',', '1,2,3')}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Split" => [',', '1,2,3']}
            }
          }
        )
      end
    end

    context "Fn::Sub" do
      it "generates the correct output with a name/value arg" do
        template.resource "Res" do
          {k: fn.sub('input', "Var" => "Value")}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Sub" => ['input', {'Var' => 'Value'}]}
            }
          }
        )
      end

      it "generates the correct output with a name/value arg" do
        template.resource "Res" do
          {k: fn.sub('input')}
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {"Fn::Sub" => 'input'}
            }
          }
        )
      end
    end

    context "Fn::Transform" do
      it "generates the correct output" do
        template.resource "Res" do
          {
            k: fn.transform('MacroName', 'Parameter' => 'Value')
          }
        end

        expect(template.to_hash['Resources']).to eq(
          {
            "Res" => {
              k: {
                "Fn::Transform" => {
                  "Name" => "MacroName",
                  "Parameters" => {
                    "Parameter" => "Value"
                  }
                }
              }
            }
          }
        )
      end
    end
  end
end
