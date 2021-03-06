module Cumuliform
  module Error
    # The base error class for id-related errors
    class IDError < StandardError
      # The logical ID this error refers to
      attr_reader :id

      # Initialize a new IDError for the given ID
      #
      # @param id [String] CloudFormation logical ID
      def initialize(id)
        @id = id
      end
    end

    # raised when a logical ID already exists
    class DuplicateLogicalID < IDError
      # returns human-readable error message
      def to_s
        "Existing item with logical ID '#{id}'"
      end
    end

    # raised when a lookup for a logical ID fails
    class NoSuchLogicalId < IDError
      # returns human-readable error message
      def to_s
        "No such logical ID '#{id}'"
      end
    end

    # raised when a Fragment with the same ID has already been defined
    class FragmentAlreadyDefined < IDError
      # returns human-readable error message
      def to_s
        "Fragment '#{id}' already defined"
      end
    end

    # raised when a Fragment lookup fails
    class FragmentNotFound < IDError
      # returns human-readable error message
      def to_s
        "No fragment with name '#{id}'"
      end
    end

    # raised when an item (e.g. Resource or Parameter) to be output contains
    # nothing
    class EmptyItem < IDError
      # returns human-readable error message
      def to_s
        "Empty item '#{id}'"
      end
    end

    # raised when the template has no Resources defined at all (CloudFormation
    # requires at least one resource)
    class NoResourcesDefined < StandardError
      # returns human-readable error message
      def to_s
        "No resources defined"
      end
    end
  end
end
