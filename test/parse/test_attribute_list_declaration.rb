require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseAttributeListDeclaration < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def test_linear_performance_space
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new("<!DOCTYPE root SYSTEM \"foo.dtd\" [<!ATTLIST " +
                            " " * n +
                            " root v CDATA #FIXED \"test\">]><root/>")
      end
    end

    def test_linear_performance_tab_and_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new("<!DOCTYPE root [<!ATTLIST " +
                            "\t" * n +
                            "root value CDATA \"" +
                            ">" * n +
                            "\">]><root/>")
      end
    end
  end
end
