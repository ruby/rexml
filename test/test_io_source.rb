# frozen_string_literal: false

require "rexml/source"

module REXMLTests
  class TestIOSource < Test::Unit::TestCase
    def setup
      @source = REXML::SourceFactory.create_from('<?xml version="1.0"?>')
    end

    sub_test_case("#read_until") do
      test("eof") do
        assert_true(@source.read("nonexistent")) # Consume all data
        assert_false(@source.read("nonexistent")) # Set EOF
        assert_equal('<?xml version="1.0"?>', @source.read_until(">"))
      end
    end
  end
end
