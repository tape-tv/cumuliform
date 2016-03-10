require_relative '../error'

module Cumuliform
  module DSL
    # DSL methods for creating and reusing template fragments
    module Fragments
      # Define a fragment for later use.
      #
      # Essentially stores a block under the name given for later use.
      #
      # @param name [Symbol] name of the fragment to define
      # @yieldparam opts [Hash] will yield the options hash passed to
      #   <tt>#fragment()</tt> when called
      # @raise [Error::FragmentAlreadyDefined] if the <tt>name</tt> is not
      #   unique in this template
      def def_fragment(name, &block)
        if fragments.has_key?(name)
          raise Error::FragmentAlreadyDefined, name
        end
        fragments[name] = block
      end

      # Use an already-defined fragment
      #
      # Retrieves the block stored under <tt>name</tt> and calls it, passing
      # any options.
      #
      # @param name [Symbol] The name of the fragment to use
      # @param opts [Hash] Options to be passed to the fragment
      # @return [Object<JSON-serialisable>] the return value of the called
      #   block
      def fragment(name, *args, &block)
        if block_given?
          warn "fragment definition form (with block) is deprecated. Use #def_fragment instead"
          def_fragment(name, *args, &block)
        else
          use_fragment(name, *args)
        end
      end

      # @api private
      def find_fragment(name)
        local_fragment = fragments[name]
        imports.reverse.reduce(local_fragment) { |fragment, import|
          fragment || import.find_fragment(name)
        }
      end

      private

      def use_fragment(name, opts = {})
        unless has_fragment?(name)
          raise Error::FragmentNotFound, name
        end
        instance_exec(opts, &find_fragment(name))
      end

      def fragments
        @fragments ||= {}
      end

      def has_fragment?(name)
        !find_fragment(name).nil?
      end
    end
  end
end
