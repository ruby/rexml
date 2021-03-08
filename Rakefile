require "rdoc/task"

require "bundler/gem_tasks"

spec = Bundler::GemHelper.gemspec

desc "Run test"
task :test do
  ruby("test/run.rb")
end

task :default => :test

namespace :warning do
  desc "Treat warning as error"
  task :error do
    def Warning.warn(*message)
      super
      raise "Treat warning as error:\n" + message.join("\n")
    end
  end
end

RDoc::Task.new do |rdoc|
  rdoc.options = spec.rdoc_options
  rdoc.rdoc_files.include(*spec.source_paths)
  rdoc.rdoc_files.include(*spec.extra_rdoc_files)
end

load "#{__dir__}/tasks/tocs.rake"
