#!/usr/bin/env ruby

$VERBOSE = true

base_dir = File.dirname(File.expand_path(__dir__))
lib_dir = File.join(base_dir, "lib")
test_dir = File.join(base_dir, "test")

$LOAD_PATH.unshift(lib_dir)

require_relative "helper"

exit(Test::Unit::AutoRunner.run(true, test_dir))
