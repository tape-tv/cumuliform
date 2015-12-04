# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'json'

module Cumuliform
  module Output
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
  end
end
