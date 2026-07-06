# frozen_string_literal: false

module REXMLTests
  class TestXPathAxisPredcedingSibling < Test::Unit::TestCase
    include REXML
    SOURCE = <<-EOF
      <a id='1'>
        <e id='2'>
          <f id='3'/>
          <f id='4'/>
          <f id='5'/>
          <f id='6'/>
        </e>
      </a>
      EOF

    def setup
      @@doc = Document.new(SOURCE) unless defined? @@doc
    end

    def test_preceding_sibling_axis
      context = XPath.first(@@doc,"/a/e/f[last()]")
      assert_equal "6", context.attributes["id"]

      prev = XPath.first(context, "preceding-sibling::f")
      assert_equal "3", prev.attributes["id"]

      prev = XPath.first(context, "preceding-sibling::f[1]")
      assert_equal "5", prev.attributes["id"]

      prev = XPath.first(context, "preceding-sibling::f[2]")
      assert_equal "4", prev.attributes["id"]

      prev = XPath.first(context, "preceding-sibling::f[3]")
      assert_equal "3", prev.attributes["id"]
    end

    def test_preceding_sibling_position_less_than
      context = XPath.first(@@doc, "/a/e/f[last()]")
      assert_equal([], XPath.match(context, "preceding-sibling::f[position() < 1]"))
      assert_equal(["5"],
                   XPath.match(context, "preceding-sibling::f[position() < 2]").map {|n| n.attributes["id"] })
      assert_equal(["4", "5"],
                   XPath.match(context, "preceding-sibling::f[position() < 3]").map {|n| n.attributes["id"] })
    end

    def test_preceding_sibling_position_less_than_or_equal
      context = XPath.first(@@doc, "/a/e/f[last()]")
      assert_equal([], XPath.match(context, "preceding-sibling::f[position() <= 0]"))
      assert_equal(["4", "5"],
                   XPath.match(context, "preceding-sibling::f[position() <= 2]").map {|n| n.attributes["id"] })
    end

    def test_preceding_sibling_position_greater_than
      context = XPath.first(@@doc, "/a/e/f[last()]")
      assert_equal(["3", "4", "5"],
                   XPath.match(context, "preceding-sibling::f[position() > 0]").map {|n| n.attributes["id"] })
      assert_equal(["3", "4"],
                   XPath.match(context, "preceding-sibling::f[position() > 1]").map {|n| n.attributes["id"] })
      assert_equal(["3"],
                   XPath.match(context, "preceding-sibling::f[position() > 2]").map {|n| n.attributes["id"] })
    end

    def test_preceding_sibling_position_greater_than_or_equal
      context = XPath.first(@@doc, "/a/e/f[last()]")
      assert_equal(["3", "4", "5"],
                   XPath.match(context, "preceding-sibling::f[position() >= 0]").map {|n| n.attributes["id"] })
      assert_equal(["3", "4", "5"],
                   XPath.match(context, "preceding-sibling::f[position() >= 1]").map {|n| n.attributes["id"] })
      assert_equal(["3", "4"],
                   XPath.match(context, "preceding-sibling::f[position() >= 2]").map {|n| n.attributes["id"] })
    end

    def test_preceding_following_sibling_multiple_anchors
      doc = Document.new(<<~XML)
        <a>
          <garbage/>
          <b id='1'/>
          <b id='2'/>
          <b id='3'/>
          <garbage/>
          <b id='4'/>
          <anchor id='a1'/>
          <b id='5'/>
          <b id='6'/>
          <garbage/>
          <garbage/>
          <b id='7'/>
          <b id='8'/>
          <garbage/>
          <b id='9'/>
          <anchor id='a2'/>
          <garbage/>
          <b id='10'/>
          <b id='11'/>
          <anchor id='a3'/>
          <b id='12'/>
        </a>
      XML

      assert_equal(%w[2 7 9], XPath.match(doc, "/a/anchor/preceding-sibling::b[position() = 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[2 3 4 7 8 9 10 11], XPath.match(doc, "/a/anchor/preceding-sibling::b[position() <= 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[2 3 4 7 8 9 10 11], XPath.match(doc, "/a/anchor/preceding-sibling::b[4 > position()]").map {|n| n.attributes["id"] })
      assert_equal(%w[1 2 3 4 5 6 7 8], XPath.match(doc, "/a/anchor/preceding-sibling::b[position() >= 4]").map {|n| n.attributes["id"] })
      assert_equal(%w[2 7 a2], XPath.match(doc, "/a/anchor/preceding-sibling::*[@id][position() = 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[2 3 4 7 8 9 a2 10 11], XPath.match(doc, "/a/anchor/preceding-sibling::*[@id][position() <= 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[1 2 3 4 a1 5 6 7 8 9], XPath.match(doc, "/a/anchor/preceding-sibling::*[@id][position() >= 4]").map {|n| n.attributes["id"] })

      assert_equal(%w[7 12], XPath.match(doc, "/a/anchor/following-sibling::b[position() = 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[5 6 7 10 11 12], XPath.match(doc, "/a/anchor/following-sibling::b[position() <= 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[8 9 10 11 12], XPath.match(doc, "/a/anchor/following-sibling::b[position() >= 4]").map {|n| n.attributes["id"] })
      assert_equal(%w[8 9 10 11 12], XPath.match(doc, "/a/anchor/following-sibling::b[3 < position()]").map {|n| n.attributes["id"] })
      assert_equal(%w[7 a3], XPath.match(doc, "/a/anchor/following-sibling::*[@id][position() = 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[5 6 7 10 11 a3 12], XPath.match(doc, "/a/anchor/following-sibling::*[@id][position() <= 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[8 9 a2 10 11 a3 12], XPath.match(doc, "/a/anchor/following-sibling::*[@id][position() >= 4]").map {|n| n.attributes["id"] })

      assert_equal(%w[1], XPath.match(doc, "/a/anchor/preceding-sibling::b[last()]").map {|n| n.attributes["id"] })
      assert_equal(%w[4], XPath.match(doc, "/a/anchor/preceding-sibling::b[last() - 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[4 5 6 7 8 9 10 11], XPath.match(doc, "/a/anchor/preceding-sibling::b[position() <= last() - 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[4 5 6 7 8 9 10 11], XPath.match(doc, "/a/anchor/preceding-sibling::b[last() - 2 > position()]").map {|n| n.attributes["id"] })
      assert_equal(%w[1 2 3 4 5], XPath.match(doc, "/a/anchor/preceding-sibling::b[position() >= last() - 4]").map {|n| n.attributes["id"] })

      assert_equal(%w[12], XPath.match(doc, "/a/anchor/following-sibling::b[last()]").map {|n| n.attributes["id"] })
      assert_equal(%w[9], XPath.match(doc, "/a/anchor/following-sibling::b[last() - 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[5 6 7 8 9], XPath.match(doc, "/a/anchor/following-sibling::b[position() <= last() - 3]").map {|n| n.attributes["id"] })
      assert_equal(%w[8 9 10 11 12], XPath.match(doc, "/a/anchor/following-sibling::b[position() >= last() - 4]").map {|n| n.attributes["id"] })
      assert_equal(%w[8 9 10 11 12], XPath.match(doc, "/a/anchor/following-sibling::b[last() - 5 < position()]").map {|n| n.attributes["id"] })
    end
  end
end
