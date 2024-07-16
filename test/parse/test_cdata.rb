require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseCData < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def test_linear_performance_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new('<description><![CDATA[ ' + ">" * n + ' ]]></description>')
      end
    end
  end
end
