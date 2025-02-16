# frozen_string_literal: false
require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseDocumentTypeDeclaration < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    private
    def parse(doctype)
      REXML::Document.new(<<-XML).doctype
#{doctype}
<r/>
      XML
    end

    class TestName < self
      def test_valid
        doctype = parse(<<-DOCTYPE)
<!DOCTYPE r>
        DOCTYPE
        assert_equal("r", doctype.name)
      end

      def test_garbage_plus_before_name_at_line_start
        exception = assert_raise(REXML::ParseException) do
          parse(<<-DOCTYPE)
<!DOCTYPE +
r SYSTEM "urn:x-rexml:test" [
]>
          DOCTYPE
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed DOCTYPE: invalid name
Line: 5
Position: 51
Last 80 unconsumed characters:
+ r SYSTEM "urn:x-rexml:test" [ ]>  <r/> 
        DETAIL
      end

      def test_no_name
        exception = assert_raise(REXML::ParseException) do
          parse(<<-DOCTYPE)
<!DOCTYPE>
          DOCTYPE
        end
        assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed DOCTYPE: name is missing
Line: 1
Position: 10
Last 80 unconsumed characters:
<!DOCTYPE>
        DETAIL
      end
    end

    class TestUnclosed < self
      def test_no_extra_node
        exception = assert_raise(REXML::ParseException) do
          REXML::Document.new("<!DOCTYPE foo [")
        end
        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed DOCTYPE: unclosed
          Line: 1
          Position: 15
          Last 80 unconsumed characters:

        DETAIL
      end

      def test_start_element
        exception = assert_raise(REXML::ParseException) do
          REXML::Document.new(<<~DOCTYPE)
            <!DOCTYPE foo [ <r>
          DOCTYPE
        end
        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed DOCTYPE: invalid declaration
          Line: 1
          Position: 20
          Last 80 unconsumed characters:
          <r>#{' '}
        DETAIL
      end

      def test_text
        exception = assert_raise(REXML::ParseException) do
          REXML::Document.new(<<~DOCTYPE)
            <!DOCTYPE foo [ text
          DOCTYPE
        end
        assert_equal(<<~DETAIL.chomp, exception.to_s)
          Malformed DOCTYPE: invalid declaration
          Line: 1
          Position: 21
          Last 80 unconsumed characters:
          text#{' '}
        DETAIL
      end
    end

    class TestExternalID < self
      class TestSystem < self
        def test_left_bracket_in_system_literal
          doctype = parse(<<-DOCTYPE)
<!DOCTYPE r SYSTEM "urn:x-rexml:[test" [
]>
          DOCTYPE
          assert_equal([
                         "r",
                         "SYSTEM",
                         nil,
                         "urn:x-rexml:[test",
                       ],
                       [
                         doctype.name,
                         doctype.external_id,
                         doctype.public,
                         doctype.system,
                       ])
        end

        def test_greater_than_in_system_literal
          doctype = parse(<<-DOCTYPE)
<!DOCTYPE r SYSTEM "urn:x-rexml:>test" [
]>
          DOCTYPE
          assert_equal([
                         "r",
                         "SYSTEM",
                         nil,
                         "urn:x-rexml:>test",
                       ],
                       [
                         doctype.name,
                         doctype.external_id,
                         doctype.public,
                         doctype.system,
                       ])
        end

        def test_no_literal
          exception = assert_raise(REXML::ParseException) do
            parse(<<-DOCTYPE)
<!DOCTYPE r SYSTEM>
            DOCTYPE
          end
          assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed DOCTYPE: system literal is missing
Line: 3
Position: 26
Last 80 unconsumed characters:
>  <r/> 
          DETAIL
        end

        def test_garbage_invalid_system_literal
          exception = assert_raise(REXML::ParseException) do
            parse(<<-DOCTYPE)
<!DOCTYPE r SYSTEM '
            DOCTYPE
          end
          assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed DOCTYPE: invalid system literal
Line: 3
Position: 27
Last 80 unconsumed characters:
 '  <r/> 
          DETAIL
        end

        def test_garbage_after_literal
          exception = assert_raise(REXML::ParseException) do
            parse(<<-DOCTYPE)
<!DOCTYPE r SYSTEM 'r.dtd'x'>
            DOCTYPE
          end
          assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed DOCTYPE: garbage after external ID
Line: 1
Position: 29
Last 80 unconsumed characters:
x'>
          DETAIL
        end

        def test_single_quote
          doctype = parse(<<-DOCTYPE)
<!DOCTYPE r SYSTEM 'r".dtd'>
          DOCTYPE
          assert_equal("r\".dtd", doctype.system)
        end

        def test_double_quote
          doctype = parse(<<-DOCTYPE)
<!DOCTYPE r SYSTEM "r'.dtd">
          DOCTYPE
          assert_equal("r'.dtd", doctype.system)
        end
      end

      class TestPublic < self
        class TestPublicIDLiteral < self
          def test_content_double_quote
            exception = assert_raise(REXML::ParseException) do
              parse(<<-DOCTYPE)
<!DOCTYPE r PUBLIC 'double quote " is invalid' "r.dtd">
              DOCTYPE
            end
            assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed DOCTYPE: invalid public ID literal
Line: 3
Position: 62
Last 80 unconsumed characters:
 'double quote " is invalid' "r.dtd">  <r/> 
            DETAIL
          end

          def test_single_quote
            doctype = parse(<<-DOCTYPE)
<!DOCTYPE r PUBLIC 'public-id-literal' "r.dtd">
            DOCTYPE
            assert_equal("public-id-literal", doctype.public)
          end

          def test_double_quote
            doctype = parse(<<-DOCTYPE)
<!DOCTYPE r PUBLIC "public'-id-literal" "r.dtd">
            DOCTYPE
            assert_equal("public'-id-literal", doctype.public)
          end
        end

        class TestSystemLiteral < self
          def test_garbage_after_literal
            exception = assert_raise(REXML::ParseException) do
              parse(<<-DOCTYPE)
<!DOCTYPE r PUBLIC 'public-id-literal' 'system-literal'x'>
              DOCTYPE
            end
            assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed DOCTYPE: garbage after external ID
Line: 1
Position: 58
Last 80 unconsumed characters:
x'>
           DETAIL
          end

          def test_single_quote
            doctype = parse(<<-DOCTYPE)
<!DOCTYPE r PUBLIC "public-id-literal" 'system"-literal'>
            DOCTYPE
            assert_equal("system\"-literal", doctype.system)
          end

          def test_double_quote
            doctype = parse(<<-DOCTYPE)
<!DOCTYPE r PUBLIC "public-id-literal" "system'-literal">
            DOCTYPE
            assert_equal("system'-literal", doctype.system)
          end
        end
      end
    end

    class TestMixed < self
      def test_entity_element
        doctype = parse(<<-INTERNAL_SUBSET)
<!ENTITY entity-name "entity content">
<!ELEMENT element-name EMPTY>
        INTERNAL_SUBSET
        assert_equal([REXML::Entity, REXML::ElementDecl],
                     doctype.children.collect(&:class))
      end

      def test_attlist_entity
        doctype = parse(<<-INTERNAL_SUBSET)
<!ATTLIST attribute-list-name attribute-name CDATA #REQUIRED>
<!ENTITY entity-name "entity content">
        INTERNAL_SUBSET
        assert_equal([REXML::AttlistDecl, REXML::Entity],
                     doctype.children.collect(&:class))
      end

      def test_notation_attlist
        doctype = parse(<<-INTERNAL_SUBSET)
<!NOTATION notation-name SYSTEM "system-literal">
<!ATTLIST attribute-list-name attribute-name CDATA #REQUIRED>
        INTERNAL_SUBSET
        assert_equal([REXML::NotationDecl, REXML::AttlistDecl],
                     doctype.children.collect(&:class))
      end

      private
      def parse(internal_subset)
        super(<<-DOCTYPE)
<!DOCTYPE r SYSTEM "urn:x-rexml:test" [
#{internal_subset}
]>
        DOCTYPE
      end
    end

    def test_linear_performance_percent_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        begin
          REXML::Document.new("<!DOCTYPE root [" + "%>" * n + "]><test/>")
        rescue
        end
      end
    end

    def test_linear_performance_comment_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new("<!DOCTYPE root [<!-- " + ">" * n + " -->]>")
      end
    end

    def test_linear_performance_external_entity_right_bracket_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new("<!DOCTYPE root [%" + "]>" * n + ";]>")
      end
    end
  end
end
