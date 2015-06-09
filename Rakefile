require 'bundler/gem_tasks'
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: [:spec]
rescue LoadError
end

EXAMPLES = Rake::FileList.new('examples/**/*.rb')
EXAMPLE_TARGETS = EXAMPLES.ext('.cform')

task :environment do
  require 'kramdown'
  $:.unshift(File.expand_path('../lib', __FILE__))
  require 'cumuliform'

  class CF
    def self.json(path)
      source = File.read(path)
      template = eval(source, binding)
      template.to_json
    end
  end
end

rule ".cform" => [".rb", "environment"] do |t|
  File.open(t.name, 'w:utf-8') { |f| f.write(CF.json(t.source)) }
end

task :examples => EXAMPLE_TARGETS
