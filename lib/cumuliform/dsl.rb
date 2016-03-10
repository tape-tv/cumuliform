require_relative 'template'
require_relative 'dsl/fragments'
require_relative 'dsl/functions'
require_relative 'dsl/import'
require_relative 'dsl/helpers'

# Cumuliform is a simple tool for generating AWS CloudFormation templates. It's
# concerned with making it easier and less error-prone to write templates by
# providing features that verify references at template generation time, rather
# than waiting for failures in stack creation. It also allows you to define and
# reuse template fragments within one template, and between many templates.
module Cumuliform
  # Create a new template from the passed-in block
  #
  # @param block the template body
  # @return [Template]
  def self.template(&block)
    template = Template.new
    template.define(&block)
  end

  # The DSL modules contain all of the public DSL methods you'll use in your templates
  module DSL
  end

  class Template
    include DSL::Import
    include DSL::Fragments
    include DSL::Functions
    include DSL::Helpers
  end
end
