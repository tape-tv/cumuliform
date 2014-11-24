# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'json'

module Cumuliform
  def self.template(&block)
    template = Template.new
    template.instance_exec(&block)
    template
  end

  class Template
    SECTIONS = {
      "Parameters" => :parameter,
      "Mappings" => :mapping,
      "Conditions" => :condition,
      "Resources" => :resource,
      "Outputs" => :output
    }

    def initialize
      SECTIONS.each do |section_name, _|
        instance_variable_set(:"@#{section_name}", {})
      end
    end

    SECTIONS.each do |section_name, method_name|
      define_method method_name do |name, hash|
        add_to_section(section_name, name, hash)
      end
    end

    def to_json
      output = {}
      SECTIONS.each do |section_name, _|
        section = get_section(section_name)
        output[section_name] = section unless section.empty?
      end
      JSON.generate(output, indent: '  ', space: ' ', object_nl: "\n")
    end

    private

    def get_section(name)
      instance_variable_get(:"@#{name}")
    end

    def add_to_section(section_name, name, hash)
      section = get_section(section_name)
      raise ArgumentError, "Existing item named '#{name}' in '#{section_name}'" if section.has_key?(name)
      section[name] = hash
    end
  end
end
