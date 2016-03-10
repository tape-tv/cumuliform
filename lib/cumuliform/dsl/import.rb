require_relative '../error'

module Cumuliform
  module DSL
    module Import
      # Import another Cumuliform::Template into this one
      #
      # @param template [Template] the template to import
      def import(template)
        imports << template
      end

      # @api private
      def has_logical_id?(logical_id)
        (imports.reverse).inject(logical_ids.include?(logical_id)) { |found, template|
          found || template.has_logical_id?(logical_id)
        }
      end

      # @api private
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
