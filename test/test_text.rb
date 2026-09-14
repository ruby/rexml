# frozen_string_literal: false

module REXMLTests
  class TextTester < Test::Unit::TestCase
    include Helper::Global
    include REXML

    def test_new_text_response_whitespace_default
      text = Text.new("a  b\t\tc", true)
      assert_equal("a b\tc", Text.new(text).to_s)
    end

    def test_new_text_response_whitespace_true
      text = Text.new("a  b\t\tc", true)
      assert_equal("a  b\t\tc", Text.new(text, true).to_s)
    end

    def test_new_text_raw_default
      text = Text.new("&amp;lt;", false, nil, true)
      assert_equal("&amp;lt;", Text.new(text).to_s)
    end

    def test_new_text_raw_false
      text = Text.new("&amp;lt;", false, nil, true)
      assert_equal("&amp;amp;lt;", Text.new(text, false, nil, false).to_s)
    end

    def test_new_text_entity_filter_default
      document = REXML::Document.new(<<-XML)
<!DOCTYPE root [
  <!ENTITY a "aaa">
  <!ENTITY b "bbb">
]>
<root/>
      XML
      text = Text.new("aaa bbb", false, document.root, nil, ["a"])
      assert_equal("aaa &b;",
                   Text.new(text, false, document.root).to_s)
    end

    def test_new_text_entity_filter_custom
      document = REXML::Document.new(<<-XML)
<!DOCTYPE root [
  <!ENTITY a "aaa">
  <!ENTITY b "bbb">
]>
<root/>
      XML
      text = Text.new("aaa bbb", false, document.root, nil, ["a"])
      assert_equal("&a; bbb",
                   Text.new(text, false, document.root, nil, ["b"]).to_s)
    end

    def test_new_text_empty_entity
      document = REXML::Document.new(<<-XML)
<!DOCTYPE root [
  <!ENTITY empty "">
  <!ENTITY a "aaa">
]>
<root/>
      XML
      assert_equal("abc &a;",
                   Text.new("abc aaa", false, document.root).to_s)
    end

    def test_shift_operator_chain
      text = Text.new("original\r\n")
      text << "append1\r\n" << "append2\r\n"
      assert_equal("original\nappend1\nappend2\n", text.to_s)
    end

    def test_shift_operator_cache
      text = Text.new("original\r\n")
      text << "append1\r\n" << "append2\r\n"
      assert_equal("original\nappend1\nappend2\n", text.to_s)
      text << "append3\r\n" << "append4\r\n"
      assert_equal("original\nappend1\nappend2\nappend3\nappend4\n", text.to_s)
    end

    def test_clone
      text = Text.new("&amp;lt; <")
      assert_equal(text.to_s,
                   text.clone.to_s)
    end

    def test_indent_text
      text = Text.new("")
      suppress_warning do
        assert_equal("\tline1\tline2\tline3", text.indent_text("line1\r\nline2\r\nline3\r\n"))
      end
    end

    def test_read_with_substitution
      suppress_warning do
        assert_equal("a <b> & \"c\" 'd' A B",
                     Text.read_with_substitution(
                       "a &lt;b&gt; &amp; &quot;c&quot; &apos;d&apos; &#65; &#x42;"))
      end
    end

    def test_read_with_substitution_illegal
      suppress_warning do
        assert_raise(REXML::ParseException) do
          Text.read_with_substitution("bad <", /</)
        end
      end
    end

    def test_expand_character_reference_decimal
      assert_equal("A", Text.expand("&#65;", nil, nil))
    end

    def test_expand_character_reference_hexadecimal
      assert_equal("A", Text.expand("&#x41;", nil, nil))
    end

    def test_expand_character_reference_supplementary_plane
      assert_equal("\u{1F600}", Text.expand("&#x1F600;", nil, nil))
    end

    def test_expand_character_reference_forbidden_null
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#0;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#0;>", exception.to_s)
    end

    def test_expand_character_reference_forbidden_start_of_heading
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#1;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#1;>", exception.to_s)
    end

    def test_expand_character_reference_forbidden_backspace
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#8;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#8;>", exception.to_s)
    end

    def test_expand_character_reference_forbidden_vertical_tab_decimal
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#11;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#11;>", exception.to_s)
    end

    def test_expand_character_reference_forbidden_vertical_tab_hexadecimal
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#xB;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#xB;>", exception.to_s)
    end

    def test_expand_character_reference_forbidden_noncharacter_fffe
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#xFFFE;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#xFFFE;>", exception.to_s)
    end

    def test_expand_character_reference_forbidden_noncharacter_ffff
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#xFFFF;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#xFFFF;>", exception.to_s)
    end

    def test_expand_character_reference_forbidden_beyond_unicode
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#x110000;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#x110000;>", exception.to_s)
    end

    def test_expand_character_reference_forbidden_out_of_range
      exception = assert_raise(REXML::ParseException) do
        Text.expand("&#x80000000;", nil, nil)
      end
      assert_equal("Illegal character reference: <&#x80000000;>", exception.to_s)
    end

    def test_unnormalize_forbidden_character_reference
      exception = assert_raise(REXML::ParseException) do
        Text.unnormalize("safe text &#0; more")
      end
      assert_equal("Illegal character reference: <&#0;>", exception.to_s)
    end

    def test_entity_value_forbidden_character_reference
      document = REXML::Document.new(
        "<!DOCTYPE a [<!ENTITY e '&#0;'>]><a>&e;</a>")
      exception = assert_raise(REXML::ParseException) do
        document.root.children.first.value
      end
      assert_equal("Illegal character reference: <&#0;>", exception.to_s)
    end
  end
end
