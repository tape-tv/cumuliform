require_relative 'section'

module Cumuliform
  SECTIONS = {
    "Parameters" => :parameter,
    "Mappings" => :mapping,
    "Conditions" => :condition,
    "Resources" => :resource,
    "Outputs" => :output
  }
  SECTION_NAMES = SECTIONS.map { |name, _| name }

  # @api private
  module Sections
    def initialize
      SECTION_NAMES.each do |section_name|
        instance_variable_set(:"@#{section_name}", Section.new(section_name, imports))
      end
    end

    def get_section(name)
      raise ArgumentError, "#{name} is not a valid template section" unless SECTION_NAMES.include?(name)
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

    def add_to_section(section_name, logical_id, block)
      if has_local_logical_id?(logical_id)
        raise Error::DuplicateLogicalID, logical_id
      end
      logical_ids << logical_id
      get_section(section_name)[logical_id] = block
    end
  end
end
