require 'bundler/gem_tasks'
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: [:spec]
rescue LoadError
end

EXAMPLES = Rake::FileList.new('examples/**/*.rb')
EXAMPLE_TARGETS = EXAMPLES.ext('.cform')

$:.unshift(File.expand_path('../lib', __FILE__))
require 'cumuliform/rake_task'

Cumuliform::RakeTask.rule(".cform" => ".rb")

desc "Generate JSON from example templates"
task :examples => EXAMPLE_TARGETS
