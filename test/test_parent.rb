# frozen_string_literal: false

module REXMLTests
  class ParentTester < Test::Unit::TestCase
    # Returns a parent that has children.
    # This is because it's not safe to test with Document,
    # which may have (and sometimes actually has) overridden Parent's methods.
    def parent_with_children
      p = REXML::Parent.new
      p.add(REXML::Element.new('a'))
      p.add(REXML::Text.new('text'))
      p.add(REXML::Element.new('b'))
      p.add(REXML::Element.new('c'))
      p
    end

    def test_index
      # No children.
      p = REXML::Parent.new
      e = REXML::Element.new('foo')
      assert_equal(nil, p.index(e))
      # Children.
      p = parent_with_children
      a, _, _, c = *p.children
      # First child.
      assert_equal(0, p.index(a))
      # Last child.
      assert_equal(3, p.index(c))
      # Not a child.
      assert_equal(nil, p.index(e))
    end

  end
end
