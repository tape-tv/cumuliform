require_relative '../error'

module Cumuliform
  module DSL
    # DSL methods for working with CloudFormation Intrinsic and Ref functions
    module Functions
      # implements the intrinsic conditions functions
      module ConditionFunctions
        # Wraps Fn::And
        #
        # see
        # http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e86066
        #
        # Behaves as a logical AND operator for CloudFormation conditions.
        # Arguments should be other conditions or things that will evaluate to
        # <tt>true</tt> or <tt>false</tt>.
        #
        # @overload and(condition_1, ..., condition_n)
        #   @param condition_1 [Hash<boolean-returning ref, intrinsic function,
        #     or condition>] Condition / value to be ANDed
        #   @param condition_n [Hash<boolean-returning ref, intrinsic function,
        #     or condition>] Condition / value to be ANDed (min 2, max 10
        #     condition args)
        # @return [Hash] the Fn::And object
        def and(*conditions)
          unless (2..10).cover?(conditions.length)
            raise ArgumentError, "You must specify AT LEAST 2 and AT MOST 10 conditions"
          end
          {"Fn::And" => conditions}
        end

        # Wraps Fn::Or
        #
        # see
        # http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e86490
        #
        # Behaves as a logical OR operator for CloudFormation conditions.
        # Arguments should be other conditions or things that will evaluate to
        # <tt>true</tt> or <tt>false</tt>.
        #
        # @overload or(condition_1, ..., condition_n)
        #   @param condition_1 [Hash<boolean-returning ref, intrinsic function,
        #     or condition>] Condition / value to be ORed
        #   @param condition_n [Hash<boolean-returning ref, intrinsic function,
        #     or condition>] Condition / value to be ORed (min 2, max 10
        #     condition args)
        # @return [Hash] the Fn::Or object
        def or(*conditions)
          unless (2..10).cover?(conditions.length)
            raise ArgumentError, "You must specify AT LEAST 2 and AT MOST 10 conditions"
          end
          {"Fn::Or" => conditions}
        end

        # Wraps Fn::Not
        #
        # see
        # http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e86402
        #
        # Behaves as a logical NOT operator for CloudFormation conditions. The
        # argument should be another condition or something that will evaluate
        # to <tt>true</tt> or <tt>false</tt>
        #
        # @param condition [Hash<boolean-returning ref, intrinsic function, or
        #   condition>] Condition / value to be NOTed
        # @return [Hash] the Fn::Not object
        def not(condition)
          {"Fn::Not" => [condition]}
        end

        # Wraps Fn::Equals
        #
        # see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e86148
        #
        # The arguments should be the literal values or refs you want to
        # compare. Returns true or false when CloudFormation evaluates the
        # template.
        #
        # @param value [String, Hash<value-returning ref>]
        # @param other_value [String, Hash<value-returning ref>]
        # @return [Hash] the Fn::Equals object
        def equals(value, other_value)
          {"Fn::Equals" => [value, other_value]}
        end

        # Wraps Fn::If
        #
        # see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html#d0e86223
        #
        # CloudFormation evaluates the Condition referred to the logical ID in
        # the <tt>condition</tt> arg and returns the <tt>true_value</tt> if
        # <tt>true</tt> and <tt>false_value</tt> otherwise. <tt>condition</tt>
        # cannot be an <tt>Fn::Ref</tt>, but you can use our <tt>xref()</tt>
        # helper to ensure the logical ID is valid.
        #
        # @param condition[String] the Logical ID of the Condition to be
        #   checked
        # @param true_value the value to be returned if <tt>condition</tt>
        #   evaluates true
        # @param false_value the value to be returned if <tt>condition</tt>
        #   evaluates false
        # @return [Hash] the Fn::If object
        def if(condition, true_value, false_value)
          {"Fn::If" => [condition, true_value, false_value]}
        end

      end
      # implements wrappers for the intrinsic functions Fn::*
      class IntrinsicFunctions
        include ConditionFunctions

        # @api private
        attr_reader :template

        # @api private
        def initialize(template)
          @template = template
        end

        # Wraps Fn::FindInMap
        #
        # see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html
        #
        # @param mapping_logical_id [String] The logical ID of the mapping we
        #   want to look up a value from
        # @param level_1_key [String] Key 1
        # @param level_2_key [String] Key 2
        # @return [Hash] the Fn::FindInMap object
        def find_in_map(mapping_logical_id, level_1_key, level_2_key)
          template.verify_mapping_logical_id!(mapping_logical_id)
          {"Fn::FindInMap" => [mapping_logical_id, level_1_key, level_2_key]}
        end

        # Wraps Fn::GetAtt
        #
        # see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html
        #
        # @param resource_logical_id [String] The Logical ID of resource we
        #   want to get an attribute of
        # @param attr_name [String] The name of the attribute to get the value
        #   of
        # @return [Hash] the Fn::GetAtt object
        def get_att(resource_logical_id, attr_name)
          template.verify_resource_logical_id!(resource_logical_id)
          {"Fn::GetAtt" => [resource_logical_id, attr_name]}
        end

        # Wraps Fn::Join
        #
        # see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html
        #
        # @param separator [String] The separator string to join the array
        #   elements with
        # @param args [Array<String>] The array of strings to join
        # @return [Hash] the Fn::Join object
        def join(separator, args)
          raise ArgumentError, "Second argument must be an Array" unless args.is_a?(Array)
          {"Fn::Join" => [separator, args]}
        end

        # Wraps Fn::Base64
        #
        # see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-base64.html
        #
        # The argument should either be a string or an intrinsic function that
        # evaluates to a string when CloudFormation executes the template
        #
        # see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-base64.html
        #
        # @param value [String, Hash<string-returning instrinsic function>] The
        #   separator string to join the array  elements with
        # @return [Hash] the Fn::Base64 object
        def base64(value)
          {"Fn::Base64" => value}
        end

        # Wraps Fn::GetAZs
        #
        # CloudFormation evaluates this to an array of availability zone names.
        #
        # see http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html
        #
        # @param value [String, Hash<ref('AWS::Region')>] The AWS region to get
        #   the array of Availability Zones of. Empty string (the default) is
        #   equivalent to specifying `ref('AWS::Region')` which evaluates to
        #   the region the stack is being created in
        # @return [Hash] the Fn::GetAZs object
        def get_azs(value = "")
          {"Fn::GetAZs" => value}
        end

        # Wraps Fn::Select
        #
        # see
        # http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-select.html
        #
        # CloudFormation evaluates the <tt>index</tt> (which can be an
        # integer-as-a-string or a <tt>ref</tt> which evaluates to a number)
        # and returns the corresponding item from the array (which can be an
        # array literal, or the result of <tt>Fn::GetAZs</tt>, or one of
        # <tt>Fn::GetAtt</tt>, <tt>Fn::If</tt>, and <tt>Ref</tt> (if they would
        # return an Array).
        #
        # @param index [Integer, Hash<value-returning ref>] The index to
        #   retrieve from <tt>array</tt>
        # @param array [Array, Hash<array-returning ref of intrinsic function>]
        #   The array to retrieve from
        # @return [Hash] the Fn::Select object
        def select(index, array)
          ref_style_index = index.is_a?(Hash) && index.has_key?("Fn::Ref")
          positive_int_style_index = index.is_a?(Integer) && index >= 0
          unless ref_style_index || positive_int_style_index
            raise ArgumentError, "index must be a positive integer or Fn::Ref"
          end
          if positive_int_style_index
            if array.is_a?(Array) && index >= array.length
              raise IndexError, "index must be in the range 0 <= index < array.length"
            end
            index = index.to_s
          end
          {"Fn::Select" => [index, array]}
        end

        # Wraps Fn::Cidr
        #
        # see
        # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-cidr.html
        #
        # @param ip_block [String] The user-specified CIDR address block to be
        #   split into smaller CIDR blocks. (e.g. "10.0.0.0/16")
        # @param count [Integer] The number of CIDRs to generate. Valid range is
        #   between 1 and 256.
        # @param cidr_bits [Integer] The number of subnet bits for the CIDR. For
        #   example, specifying a value "8" for this parameter will create a
        #   CIDR with a mask of "/24".
        # @return [Hash] The Fn::Cidr object
        def cidr(ip_block, count, cidr_bits)
          {"Fn::Cidr" => [ip_block, count, cidr_bits]}
        end

        # Wraps Fn::ImportValue
        #
        # see
        # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html
        #
        # @param shared_value_to_import [String] The stack output value to
        #   import
        # @return [Hash] The Fn::ImportValue object
        def import_value(shared_value_to_import)
          {"Fn::ImportValue" => shared_value_to_import}
        end

        # Wraps Fn::Split
        #
        # see
        # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-split.html
        #
        # @param delimiter [String] The delimiter to split the source_string on
        # @param source_string [String] The string to split
        # @return [Hash] The Fn::Split object
        def split(delimiter, source_string)
          {"Fn::Split" => [delimiter, source_string]}
        end

        # Wraps Fn::Sub
        #
        # see
        # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html
        #
        # @param string [String] The string to substitute values into
        # @param substitutions [Hash<String => String,Hash>] Optional hash of
        #   variable names and the value to substitute them for. The value can
        #   also be somethings like an Fn:Ref invocation.
        # @return [Hash] The Fn::Sub object
        def sub(string, substitutions = nil)
          if substitutions.nil?
            args = string
          else
            args = [string, substitutions]
          end
          {"Fn::Sub" => args}
        end

        # Wraps Fn::Transform
        #
        # see
        # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-transform.html
        #
        # @param macro_name [String] The name of the macro to call
        # @param parameters [Hash] The hash of parameter names/values
        # @return [Hash] The Fn::Transform object
        def transform(macro_name, parameters = {})
          {
            "Fn::Transform" => {
              "Name" => macro_name,
              "Parameters" => parameters
            }
          }
        end
      end

      # Checks <tt>logical_id</tt> is present and either returns
      # <tt>logical_id</tt> or raises Cumuliform::Error::NoSuchLogicalId.
      #
      # You can use it anywhere you need a string Logical ID and want the
      # protection of having it be verified, for example in the
      # <tt>cfn-init</tt> invocation in a Cfn::Init metadata block or the
      # condition name field of, e.g. Fn::And.
      #
      # @param logical_id [String] the logical ID you want to check
      # @return [String] the logical_id param
      def xref(logical_id)
        unless has_logical_id?(logical_id)
          raise Error::NoSuchLogicalId, logical_id
        end
        logical_id
      end

      # Wraps Ref
      #
      # CloudFormation evaluates the <tt>Ref</tt> and returns the value of the
      # Parameter or Resource with Logical ID <tt>logical_id</tt>.
      #
      # @param logical_id [String] The logical ID of the parameter or resource
      # @return [Hash] the Ref object
      def ref(logical_id)
        {"Ref" => xref(logical_id)}
      end

      # returns an instance of IntrinsicFunctions which provides wrappers for
      # Fn::* functions
      # @return [IntrinsicFunctions] the DSL wrapper
      def fn
        @fn ||= IntrinsicFunctions.new(self)
      end
    end
  end
end
