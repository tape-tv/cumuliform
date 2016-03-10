require_relative '../error'

module Cumuliform
  module DSL
    module Helpers
      # Add helper methods to the template
      #
      # @overload helpers(mod, ...)
      #   Include one or more helper modules
      #   @param mod [Module] Module containing helper methods to include
      # @overload helpers(&block)
      #   @param block [lambda] Block containing helper method definitins to include
      def helpers(*mods, &block)
        if block_given?
          mods << Module.new(&block)
        end
        mods.each do |mod|
          helpers_class.class_eval {
            include mod
          }
        end
      end

      protected

      def has_helper?(meth)
        helpers_instance.respond_to?(meth)
      end

      def template_for_helper(meth)
        return self if has_helper?(meth)
        imports.reverse.find { |template|
          template.template_for_helper(meth)
        }
      end

      def send_helper(meth, *args)
        helpers_instance.send(meth, *args)
      end

      private

      def helpers_class
        @helpers_class ||= Class.new
      end

      def helpers_instance
        @helpers_instance ||= helpers_class.new
      end

      def method_missing(meth, *args)
        if template = template_for_helper(meth)
          template.send_helper(meth, *args)
        else
          super
        end
      end
    end
  end
end
