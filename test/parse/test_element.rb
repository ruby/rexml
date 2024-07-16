require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseElement < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def parse(xml)
      REXML::Document.new(xml)
    end

    class TestInvalid < self
      def test_top_level_end_tag
        exception = assert_raise(REXML::ParseException) do
          parse("</a>")
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Unexpected top-level end tag (got 'a')
Line: 1
Position: 4
Last 80 unconsumed characters:

        DETAIL
      end

      def test_no_end_tag
        exception = assert_raise(REXML::ParseException) do
          parse("<a></")
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Missing end tag for 'a'
Line: 1
Position: 5
Last 80 unconsumed characters:
</
        DETAIL
      end

      def test_empty_namespace_attribute_name
        exception = assert_raise(REXML::ParseException) do
          parse("<x :a=\"\"></x>")
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Invalid attribute name: <:a="">
Line: 1
Position: 13
Last 80 unconsumed characters:
:a=""></x>
        DETAIL
      end

      def test_empty_namespace_attribute_name_with_utf8_character
        exception = assert_raise(REXML::ParseException) do
          parse("<x :\xE2\x80\x8B>") # U+200B ZERO WIDTH SPACE
        end
        assert_equal(<<-DETAIL.chomp.force_encoding("ASCII-8BIT"), exception.to_s)
Invalid attribute name: <:\xE2\x80\x8B>
Line: 1
Position: 8
Last 80 unconsumed characters:
:\xE2\x80\x8B>
        DETAIL
      end

      def test_garbage_less_than_before_root_element_at_line_start
        exception = assert_raise(REXML::ParseException) do
          parse("<\n<x/>")
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
malformed XML: missing tag start
Line: 2
Position: 6
Last 80 unconsumed characters:
< <x/>
        DETAIL
      end

      def test_garbage_less_than_slash_before_end_tag_at_line_start
        exception = assert_raise(REXML::ParseException) do
          parse("<x></\n</x>")
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Missing end tag for 'x'
Line: 2
Position: 10
Last 80 unconsumed characters:
</ </x>
        DETAIL
      end

      def test_after_root
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<a></a><b>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: Extra tag at the end of the document (got '<b')
          Line: 1
          Position: 10
          Last 80 unconsumed characters:

        DETAIL
      end

      def test_after_empty_element_tag_root
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<a/><b>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: Extra tag at the end of the document (got '<b')
          Line: 1
          Position: 7
          Last 80 unconsumed characters:

        DETAIL
      end
    end

    def test_linear_performance_attribute_value_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new('<test testing="' + ">" * n + '"></test>')
      end
    end
  end
end
