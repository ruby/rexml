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
