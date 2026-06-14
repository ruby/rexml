# frozen_string_literal: false

module REXMLTests
  class TestXPathAttribute < Test::Unit::TestCase
    def setup
      @xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root xmlns="http://example.com/">
  <child name="one">child1</child>
  <child name="two">child2</child>
  <child name="three">child3</child>
</root>
      XML
      @document = REXML::Document.new(@xml)
    end

    def test_elements
      root = @document.elements["root"]
      second_child = root.elements["child[@name='two']"]
      assert_equal("child2", second_child.text)
    end

    def test_xpath_each
      children = REXML::XPath.each(@document, "/root/child[@name='two']")
      assert_equal(["child2"], children.collect(&:text))
    end

    def test_no_namespace
      children = REXML::XPath.match(@document,
                                    "/root/child[@nothing:name='two']",
                                    "" => "http://example.com/",
                                    "nothing" => "")
      assert_equal(["child2"], children.collect(&:text))
    end

    def test_attribute_axis_with_other_axes_does_not_raise
      # Some of those are not yet supported in REXML, but at least it shouldn't raise an error
      assert_nothing_raised do
        REXML::XPath.match(@document, '//attribute::*/parent::*')
        REXML::XPath.match(@document, '//attribute::*/preceding::*')
        REXML::XPath.match(@document, '//attribute::*/following::*')
        REXML::XPath.match(@document, '//attribute::*/preceding-sibling::*')
        REXML::XPath.match(@document, '//attribute::*/following-sibling::*')
        REXML::XPath.match(@document, '//attribute::*/ancestor::*')
        REXML::XPath.match(@document, '//attribute::*/descendant::*')
        REXML::XPath.match(@document, '//attribute::*/ancestor-or-self::*')
        REXML::XPath.match(@document, '//attribute::*/descendant-or-self::*')
      end
    end
  end
end
