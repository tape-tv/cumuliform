module Cumuliform
  module Error
    class IDError < StandardError
      attr_reader :id

      def initialize(id)
        @id = id
      end
    end

    class DuplicateLogicalID < IDError
      def to_s
        "Existing item with logical ID '#{id}'"
      end
    end

    class NoSuchLogicalId < IDError
      def to_s
        "No such logical ID '#{id}'"
      end
    end

    class FragmentAlreadyDefined < IDError
      def to_s
        "Fragment '#{id}' already defined"
      end
    end

    class FragmentNotFound < IDError
      def to_s
        "No fragment with name '#{id}'"
      end
    end

    class EmptyItem < IDError
      def to_s
        "Empty item '#{id}'"
      end
    end

    class NoResourcesDefined < StandardError
      def to_s
        "No resources defined"
      end
    end
  end
end
