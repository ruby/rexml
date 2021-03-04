require "bundler/gem_tasks"

desc "Run test"
task :test do
  ENV["RUBYOPT"] = "-Ilib -Itest/lib -rbundler/setup -rhelper"
  ruby("run-test.rb")
end

task :sync_tool do
  require 'fileutils'
  FileUtils.cp "../ruby/tool/lib/test/unit/core_assertions.rb", "./test/lib"
  FileUtils.cp "../ruby/tool/lib/envutil.rb", "./test/lib"
  FileUtils.cp "../ruby/tool/lib/find_executable.rb", "./test/lib"
end

task :default => :test
