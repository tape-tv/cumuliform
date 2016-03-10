# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'set'
require_relative 'error'
require_relative 'dsl/fragments'
require_relative 'dsl/functions'
require_relative 'dsl/import'
require_relative 'dsl/helpers'
require_relative 'sections'
require_relative 'output'

module Cumuliform
  AWS_PSEUDO_PARAMS = %w{
      AWS::AccountId AWS::NotificationARNs AWS::NoValue
      AWS::Region AWS::StackId AWS::StackName
  }

  class Template
    include DSL::Import
    include DSL::Fragments
    include DSL::Functions
    include DSL::Helpers
    include Output
    include Sections

    def define(&block)
      instance_exec(&block)
      self
    end

    def logical_ids
      @logical_ids ||= Set.new(AWS_PSEUDO_PARAMS)
    end

    private

    def has_local_logical_id?(logical_id)
      logical_ids.include?(logical_id)
    end
  end
end
