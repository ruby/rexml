# frozen_string_literal: false

module REXMLTests
  class TextCheckTester < Test::Unit::TestCase
    include REXML

    def test_valid_pattern
      chars = ['&A;', '&:;', '&_;', '&:A;', '&AA.bb-00;']
      chars.each do |token|
        text = Text.new(token, false, nil, true)
        assert_equal(token, text.to_s)
      end

      character_entities = ['&amp;', '&lt;', '&gt;', '&quot;', '&apos;', '&nbsp;', '&Psi;']
      character_entities.each do |token|
        text = Text.new(token, false, nil, true)
        assert_equal(token, text.to_s)
      end

      numeric_entities = ['&#13;', '&#34;', '&#9830;', '&#0000000013;', '&#0000000162;', '&#x10FFFF;', '&#1114111;']
      numeric_entities.each do |token|
        text = Text.new(token, false, nil, true)
        assert_equal(token, text.to_s)
      end

      unicode_entities = ['&#x9;', '&#xa;', '&#xD;', '&#x84;', '&#x9F;', '&#xFDEF;', '&#x10FFFF;', '&#x000000007f;']
      unicode_entities.each do |token|
        text = Text.new(token, false, nil, true)
        assert_equal(token, text.to_s)
      end

      unicodes = ["&\u00C0;", "&\uFDF0;", "&\u{10000};", "&\u00D6\u0300\u0300;"]
      unicodes.each do |token|
        text = Text.new(token, false, nil, true)
        assert_equal(token, text.to_s)
      end
    end

    def test_invalid_pattern
      chars = ['<', '<;', '&amp', '&42;','&#A;', '&#8;', '&#xB;', '&#x1f;', '&#xD800;', '&#xFFFE;', '&#x110000;', '&#1114112;']
      chars.each do |token|
        assert_raise(RuntimeError) { Text.new(token, false, nil, true) }
      end

      unicodes = ["&\u00BF;", "&\u{F0000};"]
      unicodes.each do |token|
        assert_raise(RuntimeError) { Text.new(token, false, nil, true) }
      end
    end
  end
end
