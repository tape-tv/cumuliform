require 'cumuliform'
require 'pathname'

module Cumuliform
  class Runner
    def self.process_io(io)
      mod = Module.new
      path = io.respond_to?(:path) ? io.path : nil
      args = [io.read, path].compact
      template = mod.class_eval(*args)
    end

    def self.process(input_path, output_path)
      input_path = Pathname.new(input_path)
      output_path = Pathname.new(output_path)

      template = process_io(input_path.open)
      output_path.open('w:utf-8') { |f| f.write(template.to_json) }
    end
  end
end
