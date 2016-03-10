# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'set'
require_relative 'error'
require_relative 'sections'
require_relative 'output'

module Cumuliform
  AWS_PSEUDO_PARAMS = %w{
      AWS::AccountId AWS::NotificationARNs AWS::NoValue
      AWS::Region AWS::StackId AWS::StackName
  }

  # Represents a single CloudFormation template
  class Template
    include Output
    include Sections

    # @api private
    def define(&block)
      instance_exec(&block)
      self
    end

    private

    def logical_ids
      @logical_ids ||= Set.new(AWS_PSEUDO_PARAMS)
    end

    def has_local_logical_id?(logical_id)
      logical_ids.include?(logical_id)
    end
  end
end
