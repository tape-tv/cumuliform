require_relative 'error'

module Cumuliform
  module Fragments
    def fragments
      @fragments ||= {}
    end

    def def_fragment(name, &block)
      if fragments.has_key?(name)
        raise Error::FragmentAlreadyDefined, name
      end
      fragments[name] = block
    end

    def fragment(name, opts = {})
      unless has_fragment?(name)
        raise Error::FragmentNotFound, name
      end
      instance_exec(opts, &find_fragment(name))
    end

    def find_fragment(name)
      local_fragment = fragments[name]
      imports.reverse.reduce(local_fragment) { |fragment, import|
        fragment || import.find_fragment(name)
      }
    end

    def has_fragment?(name)
      !find_fragment(name).nil?
    end
  end
end
