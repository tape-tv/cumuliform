# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'json'
require 'set'
require_relative 'cumuliform/error'
require_relative 'cumuliform/fragments'
require_relative 'cumuliform/functions'
require_relative 'cumuliform/output'

module Cumuliform
  AWS_PSEUDO_PARAMS = %w{
      AWS::AccountId AWS::NotificationARNs AWS::NoValue
      AWS::Region AWS::StackId AWS::StackName
  }
  SECTIONS = {
    "Parameters" => :parameter,
    "Mappings" => :mapping,
    "Conditions" => :condition,
    "Resources" => :resource,
    "Outputs" => :output
  }

  def self.template(&block)
    template = Template.new
    template.define(&block)
  end

  class Template
    include Fragments
    include Functions
    include Output

    attr_reader :logical_ids

    def initialize
      @logical_ids = Set.new(AWS_PSEUDO_PARAMS)
      SECTIONS.each do |section_name, _|
        instance_variable_set(:"@#{section_name}", {})
      end
    end

    def define(&block)
      instance_exec(&block)
      self
    end

    SECTIONS.each do |section_name, method_name|
      define_method method_name, ->(logical_id, &block) {
        add_to_section(section_name, logical_id, block)
      }
    end

    private

    def has_logical_id?(logical_id)
      logical_ids.include?(logical_id)
    end

    def get_section(name)
      instance_variable_get(:"@#{name}")
    end

    def add_to_section(section_name, logical_id, block)
      if has_logical_id?(logical_id)
        raise Error::DuplicateLogicalID, logical_id
      end
      logical_ids << logical_id
      get_section(section_name)[logical_id] = block
    end
  end
end
