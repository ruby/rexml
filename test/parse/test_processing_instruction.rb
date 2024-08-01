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
Malformed XML: Unclosed processing instruction
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
Malformed XML: Unclosed processing instruction
Line: 1
Position: 6
Last 80 unconsumed characters:

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
        REXML::Document.new("<?xml version=\"1.0\" " + ">" * n + " ?>")
      end
    end

    def test_linear_performance_tab
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new("<?name" + "\t" * n + "version=\"1.0\" > ?>")
      end
    end
  end
end
