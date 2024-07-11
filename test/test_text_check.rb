# frozen_string_literal: false

module REXMLTests
  class TextCheckTester < Test::Unit::TestCase

    def check(string)
      REXML::Text.check(string, REXML::Text::NEEDS_A_SECOND_CHECK, nil)
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
        string = "<;"
        assert_raise(RuntimeError.new("Illegal character \"<\" in raw string #{string.inspect}")) { check(string) }
      end

      def test_entity_reference_missing_colon
        string = "&amp"
        assert_raise(RuntimeError.new("Illegal character \"&\" in raw string #{string.inspect}")) { check(string) }
      end

      def test_character_reference_decimal_invalid_value
        string = "&#8;"
        assert_raise(RuntimeError.new("Illegal character #{string.inspect} in raw string #{string.inspect}")) { check(string) }
      end

      def test_character_reference_hex_invalid_value
        string = "&#xD800;"
        assert_raise(RuntimeError.new("Illegal character #{string.inspect} in raw string #{string.inspect}")) { check(string) }
      end

      def test_entity_name_non_ascii_invalid_value
        string = "&\u00BF;"
        assert_raise(RuntimeError.new("Illegal character \"&\" in raw string #{string.inspect}")) { check(string) }
      end
    end
  end
end
