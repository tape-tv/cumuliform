require 'spec_helper'

module Cumuliform
  describe "Template definition" do
    let(:template) { Template.new }

    it "allows template definition with a block" do
      template.define {
        resource 'Hello' do
          {k: 'v'}
        end
      }

      expect(template.to_hash['Resources']).to eq({'Hello' => {k: 'v'}})
    end
  end
end
