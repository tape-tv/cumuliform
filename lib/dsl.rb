# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'json'
require 'set'

module Cumuliform
  module Error
    class IDError < StandardError
      attr_reader :id

      def initialize(id)
        @id = id
      end
    end

    class DuplicateLogicalID < IDError
      def to_s
        "Existing item with logical ID '#{id}'"
      end
    end

    class NoSuchLogicalId < IDError
      def to_s
        "No such logical ID '#{id}'"
      end
    end

    class FragmentAlreadyDefined < IDError
      def to_s
        "Fragment '#{id}' already defined"
      end
    end

    class FragmentNotFound < IDError
      def to_s
        "No fragment with name '#{id}'"
      end
    end

    class EmptyItem < IDError
      def to_s
        "Empty item '#{id}'"
      end
    end

    class NoResourcesDefined < StandardError
      def to_s
        "No resources defined"
      end
    end
  end

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
      unless has_logical_id?(logical_id)
        raise Error::NoSuchLogicalId, logical_id
      end
      {"Ref" => logical_id}
    end

    def to_hash
      output = {}
      SECTIONS.each do |section_name, _|
        section = get_section(section_name)
        output[section_name] = generate_section(section) unless section.empty?
      end

      raise Error::NoResourcesDefined unless output.has_key?("Resources")
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
        raise Error::DuplicateLogicalID, logical_id
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
      raise Error::EmptyItem, logical_id if block.nil?
      item_body = instance_exec(&block)
      raise Error::EmptyItem, logical_id if item_body.empty?
      item_body
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
