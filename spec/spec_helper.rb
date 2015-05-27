require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

$:.unshift(File.expand_path('../lib', __dir__))

require 'cumuliform'
