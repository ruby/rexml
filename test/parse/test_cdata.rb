require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseCData < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def parse(xml)
      REXML::Document.new(xml)
    end

    def test_linear_performance_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        parse('<description><![CDATA[ ' + ">" * n + ' ]]></description>')
      end
    end

    class TestInvalid < self
      def test_unclosed_cdata
        exception = assert_raise(REXML::ParseException) do
          parse("<root><![CDATA[a]></root>")
        end
        assert_equal(<<~DETAIL, exception.to_s)
          Malformed CDATA: Missing end ']]>'
          Line: 1
          Position: 25
          Last 80 unconsumed characters:
        DETAIL
      end
    end
  end
end
