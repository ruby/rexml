# frozen_string_literal: false

module REXMLTests
  class ElementTester < Test::Unit::TestCase
    def test_array_reference_string
      doc = REXML::Document.new("<language name='Ruby'/>")
      assert_equal("Ruby", doc.root["name"])
    end

    def test_array_reference_symbol
      doc = REXML::Document.new("<language name='Ruby'/>")
      assert_equal("Ruby", doc.root[:name])
    end
  end
end
