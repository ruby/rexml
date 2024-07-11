# frozen_string_literal: false

module REXMLTests
  class TextCheckTester < Test::Unit::TestCase

    def check(string)
      REXML::Text.check(string, REXML::Text::NEEDS_A_SECOND_CHECK, nil)
    end

    def assert_check(string)
      assert_nothing_raised { check(string) }
    end

    def assert_check_failed(string, illegal_part)
      message = "Illegal character #{illegal_part.inspect} in raw string #{string.inspect}"
      assert_raise(RuntimeError.new(message)) do
        check(string)
      end
    end

    class TestValid < self
      def test_entity_name_start_char_colon
        assert_check("&:;")
      end

      def test_entity_name_start_char_under_score
        assert_check("&_;")
      end

      def test_entity_name_mix
        assert_check("&A.b-0123;")
      end

      def test_character_reference_decimal
        assert_check("&#0162;")
      end

      def test_character_reference_hex
        assert_check("&#x10FFFF;")
      end

      def test_entity_name_non_ascii
        # U+3042 HIRAGANA LETTER A
        # U+3044 HIRAGANA LETTER I
        assert_check("&\u3042\u3044;")
      end

      def test_normal_string
        assert_check("foo")
      end
    end

    class TestInvalid < self
      def test_lt
        assert_check_failed("<;", "<")
      end

      def test_lt_mix
        assert_check_failed("ab<cd", "<")
      end

      def test_reference_empty
        assert_check_failed("&;", "&")
      end

      def test_entity_reference_missing_colon
        assert_check_failed("&amp", "&")
      end

      def test_character_reference_decimal_garbage_at_the_end
        # U+0030 DIGIT ZERO
        assert_check_failed("&#48x;", "&")
      end

      def test_character_reference_decimal_space_at_the_start
        # U+0030 DIGIT ZERO
        assert_check_failed("&# 48;", "&")
      end

      def test_character_reference_decimal_control_character
        # U+0008 BACKSPACE
        assert_check_failed("&#8;", "&#8;")
      end

      def test_character_reference_format_hex_0x
        # U+0041 LATIN CAPITAL LETTER A
        assert_check_failed("&#0x41;", "&#0x41;")
      end

      def test_character_reference_format_hex_00x
        # U+0041 LATIN CAPITAL LETTER A
        assert_check_failed("&#00x41;", "&#00x41;")
      end

      def test_character_reference_hex_garbage_at_the_end
        # U+0030 DIGIT ZERO
        assert_check_failed("&#x48x;", "&")
      end

      def test_character_reference_hex_space_at_the_start
        # U+0030 DIGIT ZERO
        assert_check_failed("&#x 30;", "&")
      end

      def test_character_reference_hex_surrogate_block
        # U+0D800 SURROGATE PAIR
        assert_check_failed("&#xD800;", "&#xD800;")
      end

      def test_entity_name_non_ascii_symbol
        # U+00BF INVERTED QUESTION MARK
        assert_check_failed("&\u00BF;", "&")
      end

      def test_entity_name_new_line
        # U+0026 AMPERSAND
        assert_check_failed("&\namp\nx;", "&")
      end
    end
  end
end
