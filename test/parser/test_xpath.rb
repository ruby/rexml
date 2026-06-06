# frozen_string_literal: false

require "test/unit"
require "rexml/parsers/xpathparser"

module REXMLTests
  class TestParserXPathParser < Test::Unit::TestCase
    sub_test_case("#abbreviate") do
      def abbreviate(xpath)
        parser = REXML::Parsers::XPathParser.new
        parser.abbreviate(xpath)
      end

      def test_document
        assert_equal("/",
                     abbreviate("/"))
      end

      def test_raw_literal
        assert_equal("1",
                     abbreviate("1"))
      end

      def test_unary_operator
        assert_equal("-1",
                     abbreviate("-1"))
        assert_equal("/a[-/b]",
                     abbreviate("/a[-/b]"))
      end

      def test_binary_operator
        assert_equal("1 * 2 + 3 - 4",
                     abbreviate("1 * 2 + 3 - 4"))
        assert_equal("/a | /b",
                     abbreviate("/a | /b"))
        assert_equal("/a[1 + /b * 2]",
                     abbreviate("/a[1 + /b * 2]"))
      end

      def test_operand_with_path
        assert_equal("/a/b + 1",
                     abbreviate("/a/b + 1"))
      end

      def test_paren
        assert_equal("(1 + 2) * 3",
                     abbreviate("(1 + 2) * 3"))
      end

      def test_predicate_paren
        assert_equal("/a[(b + c) * d]",
                      abbreviate("/a[(b + c) * d]"))
      end

      def test_path_paren
        assert_equal("(a/b)[2]",
                     abbreviate("(a/b)[2]"))
      end

      def test_unknown_not_infinitely_recursing
        assert_instance_of(String, abbreviate([:unknown]))
      end

      def test_function
        assert_equal("string-length(a/b[last()])",
                     abbreviate("string-length(a/b[last()])"))
      end

      def test_descendant_or_self_only
        assert_equal("//",
                     abbreviate("/descendant-or-self::node()/"))
      end

      def test_descendant_or_self_absolute
        assert_equal("//a/b",
                     abbreviate("/descendant-or-self::node()/a/b"))
      end

      def test_descendant_or_self_relative
        assert_equal("a//b",
                     abbreviate("a/descendant-or-self::node()/b"))
      end

      def test_descendant_or_self_not_node
        assert_equal("/descendant-or-self::text()",
                     abbreviate("/descendant-or-self::text()"))
      end

      def test_self_absolute
        assert_equal("/a/./b",
                     abbreviate("/a/self::node()/b"))
      end

      def test_self_relative
        assert_equal("a/./b",
                     abbreviate("a/self::node()/b"))
      end

      def test_self_not_node
        assert_equal("/self::text()",
                     abbreviate("/self::text()"))
      end

      def test_parent_absolute
        assert_equal("/a/../b",
                     abbreviate("/a/parent::node()/b"))
      end

      def test_parent_relative
        assert_equal("a/../b",
                     abbreviate("a/parent::node()/b"))
      end

      def test_parent_not_node
        assert_equal("/a/parent::text()",
                     abbreviate("/a/parent::text()"))
      end

      def test_any_absolute
        assert_equal("/*/a",
                     abbreviate("/*/a"))
      end

      def test_any_relative
        assert_equal("a/*/b",
                     abbreviate("a/*/b"))
      end

      def test_following_sibling_absolute
        assert_equal("/following-sibling::a/b",
                     abbreviate("/following-sibling::a/b"))
      end

      def test_following_sibling_relative
        assert_equal("a/following-sibling::b/c",
                     abbreviate("a/following-sibling::b/c"))
      end

      def test_predicate_index
        assert_equal("a[5]/b",
                     abbreviate("a[5]/b"))
      end

      def test_attribute_relative
        assert_equal("a/@b",
                     abbreviate("a/attribute::b"))
      end

      def test_filter_attribute
        assert_equal("a/b[@i = 1]/c",
                     abbreviate("a/b[attribute::i=1]/c"))
      end

      def test_filter_string_single_quote
        assert_equal("a/b[@name = \"single ' quote\"]/c",
                     abbreviate("a/b[attribute::name=\"single ' quote\"]/c"))
      end

      def test_filter_string_double_quote
        assert_equal("a/b[@name = 'double \" quote']/c",
                     abbreviate("a/b[attribute::name='double \" quote']/c"))
      end
    end

    def test_spaces_between_tokens
      # REXML doesn't support space between function-name and opening paren.
      # Spaces after `(` and spaces around `)`, `[`, `]` are tested here.
      parser = REXML::Parsers::XPathParser.new
      assert_equal(
        parser.parse('//a/b[c][d]/e'),
        parser.parse(' // a / b [ c ] [ d ] / e '),
      )
      assert_equal(
        parser.parse('/a/b[string-length("1")<(2+3)]/c'),
        parser.parse(' / a / b [ string-length( "1" ) < ( 2 + 3 ) ] / c '),
      )
      assert_equal(
        parser.parse('//processing-instruction("a")'),
        parser.parse('//processing-instruction( "a" )'),
      )
    end
  end
end
