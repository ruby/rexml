require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseComment < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def parse(xml)
      REXML::Document.new(xml)
    end

    class TestInvalid < self
      def test_toplevel_unclosed_comment
        exception = assert_raise(REXML::ParseException) do
          parse("<!--")
        end
        assert_equal(<<~DETAIL, exception.to_s)
          Unclosed comment
          Line: 1
          Position: 4
          Last 80 unconsumed characters:
        DETAIL
      end

      def test_toplevel_malformed_comment_inner
        exception = assert_raise(REXML::ParseException) do
          parse("<!-- -- -->")
        end
        assert_equal(<<~DETAIL, exception.to_s)
          Malformed comment
          Line: 1
          Position: 11
          Last 80 unconsumed characters:
        DETAIL
      end

      def test_toplevel_malformed_comment_end
        exception = assert_raise(REXML::ParseException) do
          parse("<!-- --->")
        end
        assert_equal(<<~DETAIL, exception.to_s)
          Malformed comment
          Line: 1
          Position: 9
          Last 80 unconsumed characters:
        DETAIL
      end

      def test_doctype_malformed_comment_inner
        exception = assert_raise(REXML::ParseException) do
          parse("<!DOCTYPE foo [<!-- -- -->")
        end
        assert_equal(<<~DETAIL, exception.to_s)
          Malformed comment
          Line: 1
          Position: 26
          Last 80 unconsumed characters:
        DETAIL
      end

      def test_doctype_malformed_comment_end
        exception = assert_raise(REXML::ParseException) do
          parse("<!DOCTYPE foo [<!-- --->")
        end
        assert_equal(<<~DETAIL, exception.to_s)
          Malformed comment
          Line: 1
          Position: 24
          Last 80 unconsumed characters:
        DETAIL
      end

      def test_after_doctype_malformed_comment_short
        exception = assert_raise(REXML::ParseException) do
          parse("<a><!-->")
        end
        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed comment
          Line: 1
          Position: 8
          Last 80 unconsumed characters:
          -->
        DETAIL
      end

      def test_after_doctype_malformed_comment_inner
        exception = assert_raise(REXML::ParseException) do
          parse("<a><!-- -- -->")
        end
        assert_equal(<<~DETAIL, exception.to_s)
          Malformed comment
          Line: 1
          Position: 14
          Last 80 unconsumed characters:
        DETAIL
      end

      def test_after_doctype_malformed_comment_end
        exception = assert_raise(REXML::ParseException) do
          parse("<a><!-- --->")
        end
        assert_equal(<<~DETAIL, exception.to_s)
          Malformed comment
          Line: 1
          Position: 12
          Last 80 unconsumed characters:
        DETAIL
      end
    end

    def test_after_root
      parser = REXML::Parsers::BaseParser.new('<a></a><!-- ok comment -->')

      events = {}
      while parser.has_next?
        event = parser.pull
        events[event[0]] = event[1]
      end

      assert_equal(" ok comment ", events[:comment])
    end

    def test_gt_linear_performance
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new('<!-- ' + ">" * n + ' -->')
      end
    end

    def test_gt_linear_performance_in_element
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new('<xml><!-- ' + '>' * n + ' --></xml>')
      end
    end
  end
end
