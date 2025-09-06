require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseProcessingInstruction < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def parse(xml)
      REXML::Document.new(xml)
    end

    class TestInvalid < self
      def test_no_name
        exception = assert_raise(REXML::ParseException) do
          parse("<??>")
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed XML: Invalid processing instruction node: invalid name
Line: 1
Position: 4
Last 80 unconsumed characters:
?>
        DETAIL
      end

      def test_unclosed_content
        exception = assert_raise(REXML::ParseException) do
          parse("<?name content")
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed XML: Unclosed processing instruction: <name>
Line: 1
Position: 14
Last 80 unconsumed characters:
content
        DETAIL
      end

      def test_unclosed_no_content
        exception = assert_raise(REXML::ParseException) do
          parse("<?name")
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed XML: Unclosed processing instruction: <name>
Line: 1
Position: 6
Last 80 unconsumed characters:

        DETAIL
      end

      def test_xml_declaration_duplicated
        exception = assert_raise(REXML::ParseException) do
          parse('<?xml version="1.0"?><?xml version="1.0"?>')
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed XML: XML declaration is duplicated
Line: 1
Position: 42
Last 80 unconsumed characters:
 version="1.0"?>
        DETAIL
      end

      def test_xml_declaration_not_at_document_start
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<a><?xml version="1.0" ?></a>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: XML declaration is not at the start
          Line: 1
          Position: 25
          Last 80 unconsumed characters:
           version="1.0" ?>
        DETAIL
      end

      def test_xml_declaration_missing_spaces
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<?xml?>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: XML declaration misses spaces before version
          Line: 1
          Position: 7
          Last 80 unconsumed characters:
          ?>
        DETAIL
      end

      def test_xml_declaration_missing_version
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<?xml ?>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: XML declaration misses version
          Line: 1
          Position: 8
          Last 80 unconsumed characters:
          ?>
        DETAIL
      end

      def test_xml_declaration_unclosed_content
        exception = assert_raise(REXML::ParseException) do
          parse('<?xml version="1.0"')
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed XML: Unclosed XML declaration
Line: 1
Position: 19
Last 80 unconsumed characters:

        DETAIL
      end

      def test_xml_declaration_unclosed_content_missing_space_after_version
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<?xml version="1.0"encoding="UTF-8"?>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: Unclosed XML declaration
          Line: 1
          Position: 37
          Last 80 unconsumed characters:
          encoding="UTF-8"?>
        DETAIL
      end

      def test_xml_declaration_unclosed_content_missing_space_after_encoding
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<?xml version="1.0" encoding="UTF-8"standalone="no"?>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: Unclosed XML declaration
          Line: 1
          Position: 53
          Last 80 unconsumed characters:
          standalone="no"?>
        DETAIL
      end

      def test_xml_declaration_unclosed_content_with_unknown_attributes
        exception = assert_raise(REXML::ParseException) do
          parser = REXML::Parsers::BaseParser.new('<?xml version="1.0" test="no"?>')
          while parser.has_next?
            parser.pull
          end
        end

        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed XML: Unclosed XML declaration
          Line: 1
          Position: 31
          Last 80 unconsumed characters:
          test="no"?>
        DETAIL
      end

      def test_xml_declaration_standalone_no_yes_or_no
        exception = assert_raise(REXML::ParseException) do
          parse('<?xml version="1.0" standalone="YES"?>')
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed XML: XML declaration standalone is not yes or no : <YES>
Line: 1
Position: 38
Last 80 unconsumed characters:
?>
        DETAIL
      end
    end

    def test_comment
      doc = parse(<<-XML)
<?x y
<!--?><?x -->?>
<r/>
      XML
      assert_equal([["x", "y\n<!--"],
                    ["x", "-->"]],
                   [[doc.children[0].target, doc.children[0].content],
                    [doc.children[1].target, doc.children[1].content]])
    end

    def test_before_root
      parser = REXML::Parsers::BaseParser.new('<?abc version="1.0" ?><a></a>')

      events = {}
      while parser.has_next?
        event = parser.pull
        events[event[0]] = event[1]
      end

      assert_equal("abc", events[:processing_instruction])
    end

    def test_after_root
      parser = REXML::Parsers::BaseParser.new('<a></a><?abc version="1.0" ?>')

      events = {}
      while parser.has_next?
        event = parser.pull
        events[event[0]] = event[1]
      end

      assert_equal("abc", events[:processing_instruction])
    end

    def test_content_question
      document = REXML::Document.new("<a><?name con?tent?></a>")
      assert_equal("con?tent", document.root.children.first.content)
    end

    def test_linear_performance_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new("<?name content " + ">" * n + " ?><a/>")
      end
    end

    def test_linear_performance_tab
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new("<?name" + "\t" * n + "version=\"1.0\" > ?><a/>")
      end
    end
  end
end
