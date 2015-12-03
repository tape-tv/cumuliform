# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require_relative 'template'

module Cumuliform
  def self.template(&block)
    template = Template.new
    template.define(&block)
  end
end
