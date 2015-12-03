require_relative '../error'

module Cumuliform
  module DSL
    module Import
      def import(template)
        imports << template
      end

      def has_logical_id?(logical_id)
        (imports.reverse).inject(logical_ids.include?(logical_id)) { |found, template|
          found || template.has_logical_id?(logical_id)
        }
      end

      def verify_logical_id!(logical_id)
        raise Error::NoSuchLogicalId, logical_id unless has_logical_id?(logical_id)
        true
      end

      private

      def imports
        @imports ||= []
      end
    end
  end
end
