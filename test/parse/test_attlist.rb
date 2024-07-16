require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseAttlist < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def test_gt_linear_performance
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new('<!DOCTYPE schema SYSTEM "foo.dtd" [<!ATTLIST ' + " " * n + ' root v CDATA #FIXED "test">]>')
      end
    end
  end
end
