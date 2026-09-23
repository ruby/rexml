module REXMLTests
  class PrettyFormatterTest < Test::Unit::TestCase
    def format(node, indentation=2)
      formatter = REXML::Formatters::Pretty.new(indentation)
      output = +""
      formatter.write(node, output)
      output
    end

    class TextTest < self
      def test_source_document_is_not_modified
        document = REXML::Document.new("<a><b>hello   world</b></a>")
        format(document)
        assert_equal("<a><b>hello   world</b></a>", document.to_s)
      end

      def test_raw_text_value_is_not_modified
        text = REXML::Text.new("hello   world", true, nil, true)
        format(text)
        assert_equal("hello   world", text.value)
      end

      def test_whitespace_is_replaced_with_space
        document = REXML::Document.new("<a><b>x\ty</b></a>")
        assert_equal("<a>\n  <b>\n    x y\n  </b>\n</a>", format(document))
      end

      def test_consecutive_spaces_are_squeezed
        document = REXML::Document.new("<a><b>x   y</b></a>")
        assert_equal("<a>\n  <b>\n    x y\n  </b>\n</a>", format(document))
      end
    end
  end
end
