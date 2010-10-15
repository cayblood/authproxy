$: << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$: << File.expand_path(File.join(File.dirname(__FILE__), 'test'))

task :default => 'test:run_all'

namespace :test do
  task :run_all do
    require 'test/unit'
    Dir['test/test_*.rb'].each {|testfile| require File.basename(testfile) }
  end
end
