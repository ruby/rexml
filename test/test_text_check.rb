# frozen_string_literal: false

module REXMLTests
  class TextCheckTester < Test::Unit::TestCase

    def check(string)
      REXML::Text.check(string, REXML::Text::NEEDS_A_SECOND_CHECK, nil)
    end

    def assert_check_failed(string, illegal_part)
      message = "Illegal character #{illegal_part.inspect} in raw string #{string.inspect}"
      assert_raise(RuntimeError.new(message)) do
        check(string)
      end
    end

    class TestValid < self
      def test_entity_name_start_char_colon
        assert_nothing_raised { check('&:;') }
      end

      def test_entity_name_start_char_under_score
        assert_nothing_raised { check('&_;') }
      end

      def test_entity_name_mix
        assert_nothing_raised { check('&A.b-0123;') }
      end

      def test_character_reference_decimal
        assert_nothing_raised { check('&#0162;') }
      end

      def test_character_reference_hex
        assert_nothing_raised { check('&#x10FFFF;') }
      end

      def test_entity_name_non_ascii
        # U+3042 HIRAGANA LETTER A
        # U+3044 HIRAGANA LETTER I
        assert_nothing_raised { check("&\u3042\u3044;") }
      end
    end

    class TestInvalid < self
      def test_lt
        assert_check_failed('<;', '<')
      end

      def test_entity_reference_missing_colon
        assert_check_failed('&amp', '&')
      end

      def test_character_reference_decimal_invalid_value
        assert_check_failed('&#8;', '&#8;')
      end

      def test_character_reference_hex_invalid_value
        assert_check_failed('&#xD800;', '&#xD800;')
      end

      def test_entity_name_non_ascii_invalid_value
        assert_check_failed('&\u00BF;', '&')
      end
    end
  end
end
