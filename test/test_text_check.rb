# frozen_string_literal: false

module REXMLTests
  class TextCheckTester < Test::Unit::TestCase

    def check(string)
      REXML::Text.check(string, REXML::Text::NEEDS_A_SECOND_CHECK, nil)
    end

    class TestValid < self
      def test_entity_name_start_char_colon
        string = '&:;'
        text = check(string)
        assert_equal(string, text.to_s)
      end

      def test_entity_name_start_char_under_score
        string = '&_;'
        text = check(string)
        assert_equal(string, text.to_s)
      end

      def test_entity_name_char
        string = '&A.b-0123;'
        text = check(string)
        assert_equal(string, text.to_s)
      end

      def test_numeric_entity_decimal
        string = '&#0162;'
        text = check(string)
        assert_equal(string, text.to_s)
      end

      def test_numeric_entity_hex
        string = '&#x10FFFF;'
        text = check(string)
        assert_equal(string, text.to_s)
      end

      def test_unicode_entity
        string = "&\u00D6\u0300\u0300;"
        text = check(string)
        assert_equal(string, text.to_s)
      end
    end

    class TestInvalid < self
      def test_lt
        string = "<;"
        assert_raise(RuntimeError.new("Illegal character \"<\" in raw string #{string.inspect}")) { check(string) }
      end

      def test_missing_colon
        string = "&amp"
        assert_raise(RuntimeError.new("Illegal character \"&\" in raw string #{string.inspect}")) { check(string) }
      end

      def test_invalid_numeric_entity_decimal
        string = "&#8;"
        assert_raise(RuntimeError.new("Illegal character #{string.inspect} in raw string #{string.inspect}")) { check(string) }
      end

      def test_invalid_numeric_entity_hex
        string = "&#xD800;"
        assert_raise(RuntimeError.new("Illegal character #{string.inspect} in raw string #{string.inspect}")) { check(string) }
      end

      def test_invalid_unicode
        string = "&\u00BF;"
        assert_raise(RuntimeError.new("Illegal character \"&\" in raw string #{string.inspect}")) { check(string) }
      end
    end
  end
end
