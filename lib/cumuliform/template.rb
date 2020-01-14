# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'set'
require_relative 'error'
require_relative 'sections'
require_relative 'output'

module Cumuliform
  AWS_PSEUDO_PARAMS = %w{
    AWS::AccountId AWS::NotificationARNs AWS::NoValue AWS::Partition
    AWS::Region AWS::StackId AWS::StackName AWS::URLSuffix
  }
  TOP_LEVEL = %w{ Transform Description }

  # Represents a single CloudFormation template
  class Template
    include Output
    include Sections

    def transform(transform)
      @Transform = transform
    end

    def description(desc)
      @Description = desc
    end

    def get_top_level_value(item_name)
      raise ArgumentError, "Not an allowed top-level item name" unless TOP_LEVEL.include?(item_name)
      instance_variable_get(:"@#{item_name}")
    end

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
