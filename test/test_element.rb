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

    def test_attribute_duplicated_namespace_url
      doc = REXML::Document.new("<root xmlns='url1' xmlns:ns1='url1' " +
                                "xmlns:ns2='url2' xmlns:ns3='url2' " +
                                "a='' ns1:a='' ns1:b='' ns2:c='' ns3:d=''/>")
      root = doc.root
      attributes = [
        root.attribute("a", "url1"),
        root.attribute("b", "url1"),
        root.attribute("c", "url2"),
        root.attribute("d", "url2"),
      ]
      assert_equal(["a", "ns1:b", "ns2:c", "ns3:d"],
                   attributes.collect {|attribute| attribute&.expanded_name})
    end
  end
end
