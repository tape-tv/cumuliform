# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'json'
require 'set'
require_relative 'error'
require_relative 'dsl/fragments'
require_relative 'dsl/functions'
require_relative 'dsl/import'
require_relative 'section'
require_relative 'output'

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

  class Template
    include DSL::Import
    include DSL::Fragments
    include DSL::Functions
    include Output

    def initialize
      SECTIONS.each do |section_name, _|
        instance_variable_set(:"@#{section_name}", Section.new(section_name, imports))
      end
    end

    def helpers(*mods, &block)
      if block_given?
        mods << Module.new(&block)
      end
      mods.each do |mod|
        self.class.include mod
      end
    end

    def define(&block)
      instance_exec(&block)
      self
    end

    def logical_ids
      @logical_ids ||= Set.new(AWS_PSEUDO_PARAMS)
    end

    def get_section(name)
      instance_variable_get(:"@#{name}")
    end

    SECTIONS.each do |section_name, method_name|
      error_class = Class.new(Error::IDError) do
        def to_s
          "No logical ID '#{id}' in section"
        end
      end
      Error.const_set("NoSuchLogicalIdIn#{section_name}", error_class)

      define_method method_name, ->(logical_id, &block) {
        add_to_section(section_name, logical_id, block)
      }

      define_method :"verify_#{method_name}_logical_id!", ->(logical_id) {
        raise error_class, logical_id unless get_section(section_name).member?(logical_id)
        true
      }
    end

    private

    def has_local_logical_id?(logical_id)
      logical_ids.include?(logical_id)
    end

    def add_to_section(section_name, logical_id, block)
      if has_local_logical_id?(logical_id)
        raise Error::DuplicateLogicalID, logical_id
      end
      logical_ids << logical_id
      get_section(section_name)[logical_id] = block
    end
  end
end
