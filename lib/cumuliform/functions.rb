require_relative 'error'

module Cumuliform
  module Functions
    class IntrinsicFunctions
      attr_reader :template

      def initialize(template)
        @template = template
      end

      def find_in_map(mapping_logical_id, level_1_key, level_2_key)
        template.verify_mapping_logical_id!(mapping_logical_id)
        {"Fn::FindInMap" => [mapping_logical_id, level_1_key, level_2_key]}
      end
    end

    def xref(logical_id)
      unless has_logical_id?(logical_id)
        raise Error::NoSuchLogicalId, logical_id
      end
      logical_id
    end

    def ref(logical_id)
      {"Ref" => xref(logical_id)}
    end

    def fn
      @fn ||= IntrinsicFunctions.new(self)
    end
  end
end
