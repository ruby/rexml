# frozen_string_literal: false

module REXMLTests
  class TestXPathParser < Test::Unit::TestCase
    def setup
      @root_element = make_service_element(["urn:type1", "urn:type2"], ["http://uri"])
      @root = @root_element.root
      @element = @root_element.children[0]
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

    def test_is_first_child
      assert_kind_of(REXML::Element, @element)
    end

    def test_has_element_as_parent
      assert_kind_of(REXML::Element, @element.parent)
    end

    def test_has_element_as_root
      assert_kind_of(REXML::Element, @root)
    end

    def test_parent_is_root
      assert_equal(@root, @element.parent)
    end

    def test_has_nil_siblings
      assert_nil(@root.previous_sibling)
      assert_nil(@element.next_sibling)
    end

    def test_has_not_nil_siblings
      assert_kind_of(REXML::Element, @element.children[0].next_sibling)
      assert_kind_of(REXML::Element, @element.children[1].previous_sibling)
    end

    def test_found
      @parser = REXML::XPathParser.new
      res = @parser.parse("/Service", @root_element)
      assert_equal("[<Service> ... </>]",
                   res.to_s)
    end

    def test_not_found
      @parser = REXML::XPathParser.new
      res = @parser.parse("/nonexistent", @root_element)
      assert_equal([],
                   res)
    end
  end
end
