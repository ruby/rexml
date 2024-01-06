begin
  require_relative "lib/rexml/rexml"
rescue LoadError
  # for Ruby core repository
  require_relative "rexml"
end

Gem::Specification.new do |spec|
  spec.name          = "rexml"
  spec.version       = REXML::VERSION
  spec.authors       = ["Kouhei Sutou"]
  spec.email         = ["kou@cozmixng.org"]

  spec.summary       = %q{An XML toolkit for Ruby}
  spec.description   = %q{An XML toolkit for Ruby}
  spec.homepage      = "https://github.com/ruby/rexml"
  spec.license       = "BSD-2-Clause"

  files = [
    "LICENSE.txt",
    "NEWS.md",
    "README.md",
  ]
  rdoc_files = files.dup
  lib_path = "lib"
  spec.require_paths = [lib_path]
  lib_dir = File.join(__dir__, lib_path)
  if File.exist?(lib_dir)
    Dir.chdir(lib_dir) do
      Dir.glob("**/*.rb").each do |file|
        files << "lib/#{file}"
      end
    end
  end
  doc_path = "doc"
  doc_dir = File.join(__dir__, doc_path)
  if File.exist?(doc_dir)
    Dir.chdir(doc_dir) do
      Dir.glob("**/*.rdoc").each do |rdoc_file|
        files << "#{doc_path}/#{rdoc_file}"
        rdoc_files << "#{doc_path}/#{rdoc_file}"
      end
    end
  end
  tasks_path = "tasks"
  tasks_dir = File.join(__dir__, tasks_path)
  Dir.chdir(doc_dir) do
    Dir.glob("**/*.rake").each do |task_file|
      files << "#{tasks_path}/#{task_file}"
    end
  end
  spec.files = files
  spec.rdoc_options.concat(["--main", "README.md"])
  spec.extra_rdoc_files = rdoc_files

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_development_dependency "benchmark_driver"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
end
