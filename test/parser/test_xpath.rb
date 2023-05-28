# frozen_string_literal: false

require "test/unit"
require "rexml/parsers/xpathparser"

module REXMLTests
  class TestXPathParser < Test::Unit::TestCase
    sub_test_case("#abbreviate") do
      def abbreviate(xpath)
        parser = REXML::Parsers::XPathParser.new
        parser.abbreviate(xpath)
      end

      def test_document
        assert_equal("/",
                     abbreviate("/"))
      end
    end
  end
end
