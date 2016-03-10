require 'cumuliform'
require 'pathname'

module Cumuliform
  # The Runner class reads a template, execute it and write the generated JSON
  # to a file
  class Runner
    # Processes an IO object which will, when read, return a Cumuliform
    # template file.
    #
    # @param io [IO] The IO-like object containing the template
    # @return [Template] the parsed Cumuliform::Template object
    def self.process_io(io)
      mod = Module.new
      path = io.respond_to?(:path) ? io.path : nil
      args = [io.read, path].compact
      template = mod.class_eval(*args)
    end

    # Reads the template file at <tt>input_path</tt>, parses and executes it to generate CloudFormation JSON which is written to <tt>output_path</tt>
    #
    # @param input_path [String] The path to the input Cumuliform template file
    # @param output_path [String] The path to the output CloudFormation JSON template file
    # @return [void]
    def self.process(input_path, output_path)
      input_path = Pathname.new(input_path)
      output_path = Pathname.new(output_path)

      template = process_io(input_path.open)
      output_path.open('w:utf-8') { |f| f.write(template.to_json) }
    end
  end
end
