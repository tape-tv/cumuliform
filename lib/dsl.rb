# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'json'
require 'set'

module Cumuliform
  class DuplicateLogicalIDError < StandardError; end
  class NoResourcesDefinedError < StandardError; end
  class EmptyItemError < StandardError; end
  class NoSuchLogicalId < StandardError; end

  def self.template(&block)
    template = Template.new
    template.define(&block)
  end

  class Template
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

    def ref(logical_id)
      raise NoSuchLogicalId, logical_id unless has_logical_id?(logical_id)
      {"Ref" => logical_id}
    end

    def to_hash
      output = {}
      SECTIONS.each do |section_name, _|
        section = get_section(section_name)
        output[section_name] = generate_section(section) unless section.empty?
      end
      unless output.has_key?("Resources")
        raise NoResourcesDefinedError, "No resources defined"
      end
      output
    end

    def to_json
      JSON.pretty_generate(to_hash)
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
        raise DuplicateLogicalIDError, "Existing item with logical ID '#{logical_id}'"
      end
      logical_ids << logical_id
      get_section(section_name)[logical_id] = block
    end

    def generate_section(section)
      output = {}
      section.each do |logical_id, block|
        output[logical_id] = generate_item(logical_id, block)
      end
      output
    end

    def generate_item(logical_id, block)
      raise EmptyItemError, "Empty item '#{logical_id}'" if block.nil?
      item_body = instance_exec(&block)
      raise EmptyItemError, "Empty item '#{logical_id}'" if item_body.empty?
      item_body
    end
  end
end
