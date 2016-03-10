require 'cumuliform/runner'

module Cumuliform
  module RakeTask
    extend self

    # Rake task lib for generating Cumuliform processing rule
    # @api private
    class TaskLib < Rake::TaskLib
      include ::Rake::DSL if defined?(::Rake::DSL)

      def define_rule(rule_args)
        task_body = ->(t, args) {
          Cumuliform::Runner.process(t.source, t.name)
        }

        rule(*rule_args, &task_body)
      end
    end

    # Define a new Rake rule task to process Cumuliform templates into
    # CloudFormation JSON
    def rule(*args)
      TaskLib.new.define_rule(args)
    end
  end
end
