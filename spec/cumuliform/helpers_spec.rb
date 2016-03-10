require 'spec_helper'

module Cumuliform
  describe "helper modules" do
    context "simple definition" do
      let(:template) { Template.new }

      it "includes modules with helper functions as instance methods correctly" do
        h = Module.new do
          def da_helper
            'Helped'
          end
        end

        template.helpers(h)

        expect(template.da_helper).to eq('Helped')
      end

      it "turns blocks into modules and makes them helpers too" do
        template.helpers do
          def da_helper
            'Module-helped'
          end
        end

        expect(template.da_helper).to eq("Module-helped")
      end
    end

    context "working with imported templates" do
      let(:base) {
        Cumuliform.template {
          helpers do
            def help!
              "I need somebody"
            end

            def no_help
              "Nah"
            end
          end
        }
      }

      let(:template) {
        base_template = base
        Cumuliform.template {
          import base_template
        }
      }

      it "can use the helpers from the imported template" do
        expect(template.help!).to eq('I need somebody')
      end

      it "helpers get overridden as you would expect" do
        template.helpers do
          def help!
            "Not just anybody..."
          end
        end

        expect(template.help!).to eq('Not just anybody...')
        expect(template.no_help).to eq('Nah')
      end

      it "helpers defined in one template aren't available in an unrelated template" do
        base_template = base # ensure this has been instantiated
        new_template = Template.new

        expect { new_template.help! }.to raise_error(NoMethodError)
      end
    end
  end
end
