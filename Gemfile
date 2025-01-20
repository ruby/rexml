source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in rexml.gemspec
gemspec

group :development do
  gem "bundler"
  # This is for suppressing the following warning:
  #
  #   warning: ostruct was loaded from the standard library, but will
  #   no longer be part of the default gems starting from Ruby 3.5.0.
  #
  # This should be part of "json". We can remove this when "json"
  # depends on "ostruct" explicitly.
  gem "ostruct"
  gem "rake"
  gem "rdoc"
end

group :benchmark do
  gem "benchmark_driver"
end

group :test do
  gem "test-unit"
  gem "test-unit-ruby-core"
end
