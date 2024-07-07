require "test/unit"
require 'rexml/parsers/baseparser'

module REXMLTests
  class TestParseText < Test::Unit::TestCase
    class TestInvalid < self
      def test_after_root
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<a></a>c')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: Extra content at the end of the document (got 'c')
          Line: 1
          Position: 8
          Last 80 unconsumed characters:

        DETAIL
      end
    end
  end
end
