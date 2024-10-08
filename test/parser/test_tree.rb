# frozen_string_literal: false
require "test/unit"
require "rexml/document"
require "rexml/parsers/treeparser"

module REXMLTests
  class TestTreeParser < Test::Unit::TestCase
    private def parse(xml)
      document = REXML::Document.new
      parser = REXML::Parsers::TreeParser.new(xml, document)
      parser.parse
    end

    class TestInvalid < self
      def test_unmatched_close_tag
        xml = "<root></not-root>"
        exception = assert_raise(REXML::ParseException) do
          parse(xml)
        end
        assert_equal(<<-MESSAGE, exception.to_s)
Missing end tag for 'root' (got 'not-root')
Line: 1
Position: #{xml.bytesize}
Last 80 unconsumed characters:
        MESSAGE
      end

      def test_no_close_tag
        xml = "<root>"
        exception = assert_raise(REXML::ParseException) do
          parse(xml)
        end
        assert_equal(<<-MESSAGE, exception.to_s)
Missing end tag for '/root'
Line: 1
Position: #{xml.bytesize}
Last 80 unconsumed characters:
        MESSAGE
      end
    end
  end
end
