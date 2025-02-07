require "rdoc/task"
require "bundler/gem_tasks"
require "rake/testtask"

spec = Bundler::GemHelper.gemspec

Rake::TestTask.new do |t|
  t.verbose = true
  t.libs << "lib"
  t.ruby_opts << ["-r", "./test/helper.rb"]
  t.test_files = FileList["test/**/test_*.rb"]
end

task :default => :test

namespace :warning do
  desc "Treat warning as error"
  task :error do
    def Warning.warn(*message, **)
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

benchmark_tasks = []
namespace :benchmark do
  Dir.glob("benchmark/*.yaml").sort.each do |yaml|
    name = File.basename(yaml, ".*")
    env = {
      "RUBYLIB" => nil,
      "BUNDLER_ORIG_RUBYLIB" => nil,
    }
    command_line = [
      RbConfig.ruby, "-v", "-S", "benchmark-driver", File.expand_path(yaml),
    ]

    desc "Run #{name} benchmark"
    task name do
      puts("```")
      sh(env, *command_line)
      puts("```")
    end
    benchmark_tasks << "benchmark:#{name}"

    case name
    when /\Aparse/
      namespace name do
        desc "Run #{name} benchmark: small"
        task :small do
          puts("```")
          sh(env.merge("N_ELEMENTS" => "500", "N_ATTRIBUTES" => "1"),
             *command_line)
          puts("```")
        end
        benchmark_tasks << "benchmark:#{name}:small"
      end
    end
  end
end

desc "Run all benchmarks"
task :benchmark => benchmark_tasks

release_task = Rake.application["release"]
release_task.prerequisites.delete("build")
release_task.prerequisites.delete("release:rubygem_push")
release_task_comment = release_task.comment
if release_task_comment
  release_task.clear_comments
  release_task.comment = release_task_comment.gsub(/ and build.*$/, "")
end
