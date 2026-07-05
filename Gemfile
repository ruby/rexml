source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in rexml.gemspec
gemspec

group :development do
  gem "rake"
  gem "rdoc"
  gem 'rbs', '4.1.0.pre.2' if RUBY_ENGINE == 'jruby' # FIXME: https://github.com/ruby/rdoc/issues/1746
end

group :benchmark do
  gem "benchmark_driver"
end

group :test do
  gem "test-unit"
  gem "test-unit-ruby-core"
end
