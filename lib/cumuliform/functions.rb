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

      def get_att(resource_logical_id, attr_name)
        template.verify_resource_logical_id!(resource_logical_id)
        {"Fn::GetAtt" => [resource_logical_id, attr_name]}
      end

      def join(separator, args)
        raise ArgumentError, "Second argument must be an Array" unless args.is_a?(Array)
        {"Fn::Join" => [separator, args]}
      end

      def base64(value)
        {"Fn::Base64" => value}
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
