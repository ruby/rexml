# frozen_string_literal: true

module REXMLTests
  class TestXPathParser < Test::Unit::TestCase
    def setup
      @root_element = make_service_element(["urn:type1", "urn:type2"], ["http://uri"])
      @element = @root_element.children[0]
      @parser = REXML::XPathParser.new
    end

    def make_service_element(types, uris)
      root_element = REXML::Element.new
      element = root_element.add_element("Service")
      types.each do |type_text|
        element.add_element("Type").text = type_text
      end
      uris.each do |uri_text|
        element.add_element("URI").text = uri_text
      end
      root_element
    end

    def test_found
      res = @parser.parse("/Service", @root_element)
      assert_equal([@element],
                   res)
    end

    def test_not_found
      res = @parser.parse("/nonexistent", @root_element)
      assert_equal([],
                   res)
    end
  end
end
