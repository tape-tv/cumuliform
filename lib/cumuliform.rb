# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'json'
require 'set'
require_relative 'cumuliform/error'
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
    include Output

    attr_reader :logical_ids, :fragments

    def initialize
      @logical_ids = Set.new(AWS_PSEUDO_PARAMS)
      @fragments = {}
      SECTIONS.each do |section_name, _|
        instance_variable_set(:"@#{section_name}", {})
      end
    end

    def define(&block)
      instance_exec(&block)
      self
    end

    def fragment(name, *args, &block)
      if block_given?
        define_fragment(name, block)
      else
        include_fragment(name, *args)
      end
    end

    SECTIONS.each do |section_name, method_name|
      define_method method_name, ->(logical_id, &block) {
        add_to_section(section_name, logical_id, block)
      }
    end

    def ref(logical_id)
      {"Ref" => xref(logical_id)}
    end

    def xref(logical_id)
      unless has_logical_id?(logical_id)
        raise Error::NoSuchLogicalId, logical_id
      end
      logical_id
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

    def define_fragment(name, block)
      if fragments.has_key?(name)
        raise Error::FragmentAlreadyDefined, name
      end
      fragments[name] = block
    end

    def include_fragment(name, *args)
      unless fragments.has_key?(name)
        raise Error::FragmentNotFound, name
      end
      instance_exec(*args, &fragments[name])
    end
  end
end
