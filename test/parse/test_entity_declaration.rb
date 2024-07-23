# frozen_string_literal: false
require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseEntityDeclaration < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    private
    def xml(internal_subset)
      <<-XML
<!DOCTYPE r SYSTEM "urn:x-henrikmartensson:test" [
#{internal_subset}
]>
<r/>
      XML
    end

    def parse(internal_subset)
      REXML::Document.new(xml(internal_subset)).doctype
    end

    public

    # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-GEDecl
    class TestGeneralEntityDeclaration < self
      # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-Name
      class TestName < self
        def test_prohibited_character
          exception = assert_raise(REXML::ParseException) do
            REXML::Document.new('<!DOCTYPE root [<!ENTITY invalid&name "valid-entity-value">]>')
          end
          assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 61
Last 80 unconsumed characters:
 invalid&name \"valid-entity-value\">]>
          DETAIL
        end
      end

      # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-EntityDef
      class TestEntityDefinition < self
        # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-EntityValue
        class TestEntityValue < self
          def test_no_quote
            exception = assert_raise(REXML::ParseException) do
              REXML::Document.new('<!DOCTYPE root [<!ENTITY valid-name invalid-entity-value>]>')
            end
            assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 59
Last 80 unconsumed characters:
 valid-name invalid-entity-value>]>
            DETAIL
          end

          def test_prohibited_character
            exception = assert_raise(REXML::ParseException) do
              REXML::Document.new('<!DOCTYPE root [<!ENTITY valid-name "% &">]>')
            end
            assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 44
Last 80 unconsumed characters:
 valid-name \"% &\">]>
            DETAIL
          end
        end

        # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-ExternalID
        class TestExternalID < self
          # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-SystemLiteral
          class TestSystemLiteral < self
            def test_no_quote_in_system
              exception = assert_raise(REXML::ParseException) do
                REXML::Document.new('<!DOCTYPE root [<!ENTITY valid-name SYSTEM invalid-system-literal>]>')
              end
              assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 68
Last 80 unconsumed characters:
 valid-name SYSTEM invalid-system-literal>]>
              DETAIL
            end

            def test_no_quote_in_public
              exception = assert_raise(REXML::ParseException) do
                REXML::Document.new('<!DOCTYPE root [<!ENTITY valid-name PUBLIC "valid-pubid-literal" invalid-system-literal>]>')
              end
              assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 90
Last 80 unconsumed characters:
 valid-name PUBLIC \"valid-pubid-literal\" invalid-system-literal>]>
              DETAIL
            end
          end

          # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-PubidLiteral
          # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-PubidChar
          class TestPublicIDLiteral < self
            def test_no_quote
              exception = assert_raise(REXML::ParseException) do
                REXML::Document.new('<!DOCTYPE root [<!ENTITY valid-name PUBLIC invalid-pubid-literal "valid-system-literal">]>')
              end
              assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 90
Last 80 unconsumed characters:
 valid-name PUBLIC invalid-pubid-literal \"valid-system-literal\">]>
              DETAIL
            end

            def test_invalid_pubid_char
              exception = assert_raise(REXML::ParseException) do
                # U+3042 HIRAGANA LETTER A
                REXML::Document.new("<!DOCTYPE root [<!ENTITY valid-name PUBLIC \"\u3042\" \"valid-system-literal\">]>")
              end
              assert_equal(<<-DETAIL.force_encoding('utf-8').chomp, exception.to_s.force_encoding('utf-8'))
Malformed entity declaration
Line: 1
Position: 74
Last 80 unconsumed characters:
 valid-name PUBLIC \"\u3042\" \"valid-system-literal\">]>
              DETAIL
            end
          end
        end

        # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-NDataDecl
        class TestNotationDataDeclaration < self
          # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-NameChar
          def test_prohibited_character
            exception = assert_raise(REXML::ParseException) do
              REXML::Document.new('<!DOCTYPE root [<!ENTITY valid-name PUBLIC "valid-pubid-literal" "valid-system-literal" NDATA invalid&name>]>')
            end
            assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 109
Last 80 unconsumed characters:
 valid-name PUBLIC \"valid-pubid-literal\" \"valid-system-literal\" NDATA invalid&nam
            DETAIL
          end
        end

        def test_entity_value_and_notation_data_declaration
          exception = assert_raise(REXML::ParseException) do
            REXML::Document.new('<!DOCTYPE root [<!ENTITY valid-name "valid-entity-value" NDATA valid-ndata-value>]>')
          end
          assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 83
Last 80 unconsumed characters:
 valid-name \"valid-entity-value\" NDATA valid-ndata-value>]>
        DETAIL
        end
      end
    end

    # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-PEDecl
    class TestParsedEntityDeclaration < self
      # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-Name
      class TestName < self
        def test_prohibited_character
          exception = assert_raise(REXML::ParseException) do
            REXML::Document.new('<!DOCTYPE root [<!ENTITY % invalid&name "valid-entity-value">]>')
          end
          assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 63
Last 80 unconsumed characters:
 % invalid&name \"valid-entity-value\">]>
          DETAIL
        end
      end

      # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-PEDef
      class TestParsedEntityDefinition < self
        # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-EntityValue
        class TestEntityValue < self
          def test_no_quote
            exception = assert_raise(REXML::ParseException) do
              REXML::Document.new('<!DOCTYPE root [<!ENTITY % valid-name invalid-entity-value>]>')
            end
            assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 61
Last 80 unconsumed characters:
 % valid-name invalid-entity-value>]>
            DETAIL
          end

          def test_prohibited_character
            exception = assert_raise(REXML::ParseException) do
              REXML::Document.new('<!DOCTYPE root [<!ENTITY % valid-name "% &">]>')
            end
            assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 46
Last 80 unconsumed characters:
 % valid-name \"% &\">]>
            DETAIL
          end
        end

        # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-ExternalID
        class TestExternalID < self
          # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-SystemLiteral
          class TestSystemLiteral < self
            def test_no_quote_in_system
              exception = assert_raise(REXML::ParseException) do
                REXML::Document.new('<!DOCTYPE root [<!ENTITY % valid-name SYSTEM invalid-system-literal>]>')
              end
              assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 70
Last 80 unconsumed characters:
 % valid-name SYSTEM invalid-system-literal>]>
              DETAIL
            end

            def test_no_quote_in_public
              exception = assert_raise(REXML::ParseException) do
                REXML::Document.new('<!DOCTYPE root [<!ENTITY % valid-name PUBLIC "valid-pubid-literal" invalid-system-literal>]>')
              end
              assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 92
Last 80 unconsumed characters:
 % valid-name PUBLIC \"valid-pubid-literal\" invalid-system-literal>]>
              DETAIL
            end
          end

          # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-PubidLiteral
          # https://www.w3.org/TR/2006/REC-xml11-20060816/#NT-PubidChar
          class TestPublicIDLiteral < self
            def test_no_quote
              exception = assert_raise(REXML::ParseException) do
                REXML::Document.new('<!DOCTYPE root [<!ENTITY % valid-name PUBLIC invalid-pubid-literal "valid-system-literal">]>')
              end
              assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 92
Last 80 unconsumed characters:
 % valid-name PUBLIC invalid-pubid-literal \"valid-system-literal\">]>
              DETAIL
            end

            def test_invalid_pubid_char
              exception = assert_raise(REXML::ParseException) do
                # U+3042 HIRAGANA LETTER A
                REXML::Document.new("<!DOCTYPE root [<!ENTITY % valid-name PUBLIC \"\u3042\" \"valid-system-literal\">]>")
              end
              assert_equal(<<-DETAIL.force_encoding('utf-8').chomp, exception.to_s.force_encoding('utf-8'))
Malformed entity declaration
Line: 1
Position: 76
Last 80 unconsumed characters:
 % valid-name PUBLIC \"\u3042\" \"valid-system-literal\">]>
              DETAIL
            end
          end
        end

        def test_entity_value_and_notation_data_declaration
          exception = assert_raise(REXML::ParseException) do
            REXML::Document.new('<!DOCTYPE root [<!ENTITY % valid-name "valid-entity-value" NDATA valid-ndata-value>]>')
          end
          assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 1
Position: 85
Last 80 unconsumed characters:
 % valid-name \"valid-entity-value\" NDATA valid-ndata-value>]>
        DETAIL
        end
      end
    end

    def test_empty
      exception = assert_raise(REXML::ParseException) do
        parse(<<-INTERNAL_SUBSET)
<!ENTITY>
        INTERNAL_SUBSET
      end
      assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed entity declaration
Line: 5
Position: 70
Last 80 unconsumed characters:
>  ]> <r/> 
      DETAIL
    end

    def test_linear_performance_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new('<!DOCTYPE rubynet [<!ENTITY rbconfig.ruby_version "' + '>' * n + '">]>')
      end
    end
  end
end
