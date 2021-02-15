# frozen_string_literal: false

module REXMLTests
  class ParentTester < Test::Unit::TestCase
    def test_index
      # No children.
      doc = REXML::Document.new('<root></root>')
      root = doc.root
      e = REXML::Element.new('foo')
      assert_equal(nil, root.index(e))
      # Children.
      doc = REXML::Document.new('<root><a/><b/><c/></root>')
      root = doc.root
      a, b, c = *root
      # First child.
      assert_equal(0, root.index(a))
      # Last child.
      assert_equal(2, root.index(c))
      # Not a child.
      assert_equal(nil, root.index(e))
    end
  end
end
