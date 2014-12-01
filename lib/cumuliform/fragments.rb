require_relative 'error'

module Cumuliform
  module Fragments
    def fragments
      @fragments ||= {}
    end

    def fragment(name, *args, &block)
      if block_given?
        define_fragment(name, block)
      else
        include_fragment(name, *args)
      end
    end

    private

    def define_fragment(name, block)
      if fragments.has_key?(name)
        raise Error::FragmentAlreadyDefined, name
      end
      fragments[name] = block
    end

    def include_fragment(name, *args)
      unless fragments.has_key?(name)
        raise Error::FragmentNotFound, name
      end
      instance_exec(*args, &fragments[name])
    end
  end
end
