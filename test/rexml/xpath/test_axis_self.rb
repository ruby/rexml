# frozen_string_literal: false
require "test/unit/testcase"
require "rexml/document"

module REXMLTests
  class TestXPathAxisSelf < Test::Unit::TestCase
    def test_only
      doc = REXML::Document.new("<root><child/></root>")
      assert_equal([doc.root],
                   REXML::XPath.match(doc.root, "."))
    end

    def test_have_predicate
      doc = REXML::Document.new("<root><child/></root>")
      error = assert_raise(REXML::ParseException) do
        REXML::XPath.match(doc.root, ".[child]")
      end
      assert_equal("Garbage component exists at the end: <[child]>: <.[child]>",
                   error.message)
    end
  end
end
