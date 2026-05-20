# frozen_string_literal: false

require "rexml/xpath"
require "rexml/parsers/xpathparser"

module REXMLTests
  class TestXPathPredicate < Test::Unit::TestCase
    include REXML
    SRC=<<~EOL
    <article>
       <section role="subdivision" id="1">
          <para>free flowing text.</para>
       </section>
       <section role="division">
          <section role="subdivision" id="2">
             <para>free flowing text.</para>
          </section>
          <section role="division">
             <para>free flowing text.</para>
          </section>
       </section>
    </article>
    EOL

    def setup
      @doc = REXML::Document.new( SRC )
      @parser = REXML::Parsers::XPathParser.new

    end

    def test_predicate_only
      error = assert_raise(REXML::ParseException) do
        do_path("[article]")
      end
      assert_equal("Garbage component exists at the end: " +
                   "<[article]>: <[article]>",
                   error.message)
    end

    def test_predicates_parent
      path = '//section[../self::section[@role="division"]]'
      m = do_path( path )
      assert_equal( 2, m.size )
      assert_equal( "2", m[0].attributes["id"] )
      assert_nil( m[1].attributes["id"] )
    end

    def test_predicates_single
      path = '//section[@role="subdivision" and not(../self::section[@role="division"])]'
      m = do_path( path )
      assert_equal( 1, m.size )
      assert_equal( "1", m[0].attributes["id"] )
    end

    def test_predicates_multi
      path = '//section[@role="subdivision"][not(../self::section[@role="division"])]'
      m = do_path( path )
      assert_equal( 1, m.size )
      assert_equal( "1", m[0].attributes["id"] )
    end

    def test_predicate_multi_position
      xml = <<~XML
        <a>
          <b><c id="1"/><c id="2"/><c id="3"/><c id="4"/><c id="5"/></b>
          <b><c id="6"/><c id="7"/><c id="8"/><c id="9"/><c id="10"/></b>
        </a>
      XML
      doc = REXML::Document.new(xml)

      result = REXML::XPath.match(doc, "/a/b/c[position()>1]")
      assert_equal(%w[2 3 4 5 7 8 9 10], result.map { |node| node.attributes["id"] })

      result = REXML::XPath.match(doc, "/a/b/c[position()>1][position()>1]")
      assert_equal(%w[3 4 5 8 9 10], result.map { |node| node.attributes["id"] })

      result = REXML::XPath.match(doc, "/a/b/c[position()>1][position()>1][@id!='3']")
      assert_equal(%w[4 5 8 9 10], result.map { |node| node.attributes["id"] })

      result = REXML::XPath.match(doc, "/a/b/c[position()>1][position()>1][@id!='3'][position()!=2]")
      assert_equal(%w[4 8 10], result.map { |node| node.attributes["id"] })
    end

    def do_path( path )
      m = REXML::XPath.match( @doc, path )
      #puts path, @parser.parse( path ).inspect
      return m
    end

    def test_predicate_float_literal
      doc = REXML::Document.new("<r><a/><b/><c/><d/></r>")
      # [N.0] is equivalent to [position() = N.0] = [position() = N]
      assert_equal(["a"], REXML::XPath.match(doc, "/r/*[1.0]").map(&:name))
      assert_equal(["b"], REXML::XPath.match(doc, "/r/*[2.0]").map(&:name))
      # Non-integer numeric literals match no node.
      assert_equal([], REXML::XPath.match(doc, "/r/*[1.5]"))
    end

    def test_predicate_variable_as_position
      doc = REXML::Document.new("<r><a/><b/><c/><d/></r>")
      parser = REXML::XPathParser.new
      parser["x"] = 2
      assert_equal(["b"], parser.parse("/r/*[$x]", doc).map(&:name))
    end

    def test_get_no_siblings_terminal_nodes
      source = <<-XML
<a>
  <b number='1' str='abc'>TEXT1</b>
  <c number='1'/>
  <c number='2' str='def'>
    <b number='3'/>
    <d number='1' str='abc'>TEXT2</d>
    <b number='2'><!--COMMENT--></b>
  </c>
</a>
XML
      doc = REXML::Document.new(source)
      predicate = "count(child::node()|" +
                        "following-sibling::node()|" +
                        "preceding-sibling::node())=0"
      m = REXML::XPath.match(doc, "/descendant-or-self::node()[#{predicate}]")
      assert_equal( [REXML::Text.new("TEXT1"),
                     REXML::Text.new("TEXT2"),
                     REXML::Comment.new("COMMENT")],
                    m )
    end
  end
end
