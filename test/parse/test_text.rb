require "test/unit"
require 'rexml/parsers/baseparser'

module REXMLTests
  class TestParseText < Test::Unit::TestCase
    class TestInvalid < self
      def test_text_only
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('a')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: Content at the start of the document (got 'a')
          Line: 1
          Position: 1
          Last 80 unconsumed characters:

        DETAIL
      end

      def test_before_root
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('b<a></a>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: Content at the start of the document (got 'b')
          Line: 1
          Position: 4
          Last 80 unconsumed characters:
          <a>
        DETAIL
      end

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

    def test_whitespace_characters_after_root
      parser = REXML::Parsers::BaseParser.new('<a>b</a> ')

      events = []
      while parser.has_next?
        event = parser.pull
        case event[0]
        when :text
          events << event[1]
        end
      end

      assert_equal(["b"], events)
    end
  end
end
