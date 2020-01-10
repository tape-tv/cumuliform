# Simple AWS CloudFormation. Doesn't try to run the commands, doesn't try to
# DSLize every last thing. Simple is the watch word

require 'json'

module Cumuliform
  # Manages converting the Cumuliform::Template into a CloudFormation JSON
  # string
  module Output
    # Processes the template and returns a hash representing the CloudFormation
    # template
    #
    # @return [Hash] Hash representing the CloudFormation template
    def to_hash
      output = {}
      TOP_LEVEL.each do |item_name|
        value = get_top_level_value(item_name)
        output[item_name] = value unless value.nil?
      end
      SECTION_NAMES.each do |section_name|
        section = get_section(section_name)
        output[section_name] = generate_section(section) unless section.empty?
      end

      raise Error::NoResourcesDefined unless output.has_key?("Resources")
      output
    end

    # Generates the JSON representation of the template from the Hash
    # representation provided by #to_hash
    #
    # @return [String] JSON representation of the CloudFormation template
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
