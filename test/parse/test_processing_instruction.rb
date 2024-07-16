require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseProcessinInstruction < Test::Unit::TestCase
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
Invalid processing instruction node
Line: 1
Position: 4
Last 80 unconsumed characters:
<??>
        DETAIL
      end

      def test_garbage_text
        # TODO: This should be parse error.
        # Create test/parse/test_document.rb or something and move this to it.
        doc = parse(<<-XML)
x<?x y
<!--?><?x -->?>
<r/>
        XML
        pi = doc.children[1]
        assert_equal([
                       "x",
                       "y\n<!--",
                     ],
                     [
                       pi.target,
                       pi.content,
                     ])
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

    def test_after_root
      parser = REXML::Parsers::BaseParser.new('<a></a><?abc version="1.0" ?>')

      events = {}
      while parser.has_next?
        event = parser.pull
        events[event[0]] = event[1]
      end

      assert_equal("abc", events[:processing_instruction])
    end

    def test_gt_linear_performance
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new('<?xml version="1.0" ' + ">" * n + ' ?>')
      end
    end
  end
end
