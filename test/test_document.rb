# -*- coding: utf-8 -*-
# frozen_string_literal: false

module REXMLTests
  class TestDocument < Test::Unit::TestCase
    def test_version_attributes_to_s
      doc = REXML::Document.new(<<~eoxml)
        <?xml version="1.0" encoding="UTF-8" standalone="no"?>
        <svg  id="svg2"
              xmlns:sodipodi="foo"
              xmlns:inkscape="bar"
              sodipodi:version="0.32"
              inkscape:version="0.44.1"
        >
        </svg>
      eoxml

      string = doc.to_s
      assert_match('xmlns:sodipodi', string)
      assert_match('xmlns:inkscape', string)
      assert_match('sodipodi:version', string)
      assert_match('inkscape:version', string)
    end

    def test_new
      doc = REXML::Document.new(<<EOF)
<?xml version="1.0" encoding="UTF-8"?>
<message>Hello world!</message>
EOF
      assert_equal("Hello world!", doc.root.children.first.value)
    end

    class EntityExpansionLimitTest < Test::Unit::TestCase
      class GeneralEntityTest < self
        def test_have_value
          xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE member [
  <!ENTITY a "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">
  <!ENTITY b "&c;&c;&c;&c;&c;&c;&c;&c;&c;&c;">
  <!ENTITY c "&d;&d;&d;&d;&d;&d;&d;&d;&d;&d;">
  <!ENTITY d "&e;&e;&e;&e;&e;&e;&e;&e;&e;&e;">
  <!ENTITY e "&f;&f;&f;&f;&f;&f;&f;&f;&f;&f;">
  <!ENTITY f "&g;&g;&g;&g;&g;&g;&g;&g;&g;&g;">
  <!ENTITY g "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">
]>
<member>
&a;
</member>
XML

          doc = REXML::Document.new(xml)
          assert_raise(RuntimeError.new("entity expansion has grown too large")) do
            doc.root.children.first.value
          end

          doc = REXML::Document.new(xml)
          doc.entity_expansion_limit = 100
          assert_raise(RuntimeError.new("number of entity expansions exceeded, processing aborted.")) do
            doc.root.children.first.value
          end
          assert_equal(101, doc.entity_expansion_count)
        end

        def test_empty_value
          xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE member [
  <!ENTITY a "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">
  <!ENTITY b "&c;&c;&c;&c;&c;&c;&c;&c;&c;&c;">
  <!ENTITY c "&d;&d;&d;&d;&d;&d;&d;&d;&d;&d;">
  <!ENTITY d "&e;&e;&e;&e;&e;&e;&e;&e;&e;&e;">
  <!ENTITY e "&f;&f;&f;&f;&f;&f;&f;&f;&f;&f;">
  <!ENTITY f "&g;&g;&g;&g;&g;&g;&g;&g;&g;&g;">
  <!ENTITY g "">
]>
<member>
&a;
</member>
XML

          doc = REXML::Document.new(xml)
          assert_raise(RuntimeError.new("number of entity expansions exceeded, processing aborted.")) do
            doc.root.children.first.value
          end

          doc = REXML::Document.new(xml)
          doc.entity_expansion_limit = 100
          assert_raise(RuntimeError.new("number of entity expansions exceeded, processing aborted.")) do
            doc.root.children.first.value
          end
          assert_equal(101, doc.entity_expansion_count)
        end

        def test_with_default_entity
          xml = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE member [
  <!ENTITY a "a">
  <!ENTITY a2 "&a; &a;">
]>
<member>
&a;
&a2;
&lt;
</member>
XML

          doc = REXML::Document.new(xml)
          doc.entity_expansion_limit = 4
          assert_equal("\na\na a\n<\n", doc.root.children.first.value)

          doc = REXML::Document.new(xml)
          doc.entity_expansion_limit = 3
          assert_raise(RuntimeError.new("number of entity expansions exceeded, processing aborted.")) do
            doc.root.children.first.value
          end
        end

        def test_entity_expansion_text_limit
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE member [
  <!ENTITY a "&b;&b;&b;">
  <!ENTITY b "&c;&d;&e;">
  <!ENTITY c "xxxxxxxxxx">
  <!ENTITY d "yyyyyyyyyy">
  <!ENTITY e "zzzzzzzzzz">
]>
<member>&a;</member>
          XML

          doc = REXML::Document.new(xml)
          doc.entity_expansion_text_limit = 90
          assert_equal(90, doc.root.children.first.value.bytesize)
        end
      end
    end

    def test_tag_in_cdata_with_not_ascii_only_but_ascii8bit_encoding_source
      tag = "<b>...</b>"
      message = "こんにちは、世界！" # Hello world! in Japanese
      xml = <<EOX
<?xml version="1.0" encoding="UTF-8"?>
<message><![CDATA[#{tag}#{message}]]></message>
EOX
      xml.force_encoding(Encoding::ASCII_8BIT)
      doc = REXML::Document.new(xml)
      assert_equal("#{tag}#{message}", doc.root.children.first.value)
    end

    def test_xml_declaration_standalone
      bug2539 = '[ruby-core:27345]'
      doc = REXML::Document.new('<?xml version="1.0" standalone="no" ?>')
      assert_equal('no', doc.stand_alone?, bug2539)
      doc = REXML::Document.new('<?xml version="1.0" standalone= "no" ?>')
      assert_equal('no', doc.stand_alone?, bug2539)
      doc = REXML::Document.new('<?xml version="1.0" standalone=  "no" ?>')
      assert_equal('no', doc.stand_alone?, bug2539)
    end

    def test_no_trailing_newline
      assert_nothing_raised do
        REXML::Document.new("<?xml version=\"1.0\"?>\n<!DOCTYPE coverage SYSTEM \"http://cobertura.sourceforge.net/xml/coverage-04.dtd\">\n<!-- Generated by simplecov-cobertura version 3.0.0 (https://github.com/jessebs/simplecov-cobertura) -->")
      end
    end

    def test_each_recursive
      xml_source = <<~XML
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <root name="root">
          <x name="1_1">
            <x name="1_2">
              <x name="1_3" />
            </x>
          </x>
          <x name="2_1">
            <x name="2_2">
              <x name="2_3" />
            </x>
          </x>
          <!-- comment -->
          <![CDATA[ cdata ]]>
        </root>
      XML

      expected_names = %w[
        root
        1_1 1_2 1_3
        2_1 2_2 2_3
      ]

      document = REXML::Document.new(xml_source)

      # Node#each_recursive iterates elements only.
      # This does not iterate XML declarations, comments, attributes, CDATA sections, etc.
      actual_names = []
      document.each_recursive do |element|
        actual_names << element.attributes["name"]
      end
      assert_equal(expected_names, actual_names)
    end

    class WriteTest < Test::Unit::TestCase
      def setup
        @document = REXML::Document.new(<<-EOX.chomp)
<?xml version="1.0" encoding="UTF-8"?>
<message>Hello world!</message>
EOX
      end

      class ArgumentsTest < self
        def test_output
          output = ""
          @document.write(output)
          assert_equal(<<-EOX.chomp, output)
<?xml version='1.0' encoding='UTF-8'?>
<message>Hello world!</message>
EOX
        end

        def test_indent
          output = ""
          indent = 2
          @document.write(output, indent)
          assert_equal(<<-EOX.chomp, output)
<?xml version='1.0' encoding='UTF-8'?>
<message>
  Hello world!
</message>
EOX
        end

        def test_transitive
          output = ""
          indent = 2
          transitive = true
          @document.write(output, indent, transitive)
          assert_equal(<<-EOX.chomp, output)
<?xml version='1.0' encoding='UTF-8'?>
<message
>Hello world!</message
>
EOX
        end

        def test_ie_hack
          output = ""
          indent = -1
          transitive = false
          ie_hack = true
          document = REXML::Document.new("<empty/>")
          document.write(output, indent, transitive, ie_hack)
          assert_equal("<empty />", output)
        end

        def test_encoding
          output = ""
          indent = -1
          transitive = false
          ie_hack = false
          encoding = "Windows-31J"

          @document.xml_decl.encoding = "Shift_JIS"
          japanese_text = "こんにちは"
          @document.root.text = japanese_text
          @document.write(output, indent, transitive, ie_hack, encoding)
          assert_equal(<<-EOX.chomp.encode(encoding), output)
<?xml version='1.0' encoding='SHIFT_JIS'?>
<message>#{japanese_text}</message>
EOX
        end
      end

      class OptionsTest < self
        def test_output
          output = ""
          @document.write(:output => output)
          assert_equal(<<-EOX.chomp, output)
<?xml version='1.0' encoding='UTF-8'?>
<message>Hello world!</message>
EOX
        end

        def test_indent
          output = ""
          @document.write(:output => output, :indent => 2)
          assert_equal(<<-EOX.chomp, output)
<?xml version='1.0' encoding='UTF-8'?>
<message>
  Hello world!
</message>
EOX
        end

        def test_transitive
          output = ""
          @document.write(:output => output, :indent => 2, :transitive => true)
          assert_equal(<<-EOX.chomp, output)
<?xml version='1.0' encoding='UTF-8'?>
<message
>Hello world!</message
>
EOX
        end

        def test_ie_hack
          output = ""
          document = REXML::Document.new("<empty/>")
          document.write(:output => output, :ie_hack => true)
          assert_equal("<empty />", output)
        end

        def test_encoding
          output = ""
          encoding = "Windows-31J"
          @document.xml_decl.encoding = "Shift_JIS"
          japanese_text = "こんにちは"
          @document.root.text = japanese_text
          @document.write(:output => output, :encoding => encoding)
          assert_equal(<<-EOX.chomp.encode(encoding), output)
<?xml version='1.0' encoding='SHIFT_JIS'?>
<message>#{japanese_text}</message>
EOX
        end
      end
    end

    class BomTest < Test::Unit::TestCase
      class HaveEncodingTest < self
        def test_utf_8
          xml = <<-EOX.force_encoding("ASCII-8BIT")
<?xml version="1.0" encoding="UTF-8"?>
<message>Hello world!</message>
EOX
          bom = "\ufeff".force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)
          assert_equal("UTF-8", document.encoding)
        end

        def test_utf_16le
          xml = <<-EOX.encode("UTF-16LE").force_encoding("ASCII-8BIT")
<?xml version="1.0" encoding="UTF-16"?>
<message>Hello world!</message>
EOX
          bom = "\ufeff".encode("UTF-16LE").force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)
          assert_equal("UTF-16", document.encoding)
        end

        def test_utf_16be
          xml = <<-EOX.encode("UTF-16BE").force_encoding("ASCII-8BIT")
<?xml version="1.0" encoding="UTF-16"?>
<message>Hello world!</message>
EOX
          bom = "\ufeff".encode("UTF-16BE").force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)
          assert_equal("UTF-16", document.encoding)
        end
      end

      class NoEncodingTest < self
        def test_utf_8
          xml = <<-EOX.force_encoding("ASCII-8BIT")
<?xml version="1.0"?>
<message>Hello world!</message>
EOX
          bom = "\ufeff".force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)
          assert_equal("UTF-8", document.encoding)
        end

        def test_utf_16le
          xml = <<-EOX.encode("UTF-16LE").force_encoding("ASCII-8BIT")
<?xml version="1.0"?>
<message>Hello world!</message>
EOX
          bom = "\ufeff".encode("UTF-16LE").force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)
          assert_equal("UTF-16", document.encoding)
        end

        def test_utf_16be
          xml = <<-EOX.encode("UTF-16BE").force_encoding("ASCII-8BIT")
<?xml version="1.0"?>
<message>Hello world!</message>
EOX
          bom = "\ufeff".encode("UTF-16BE").force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)
          assert_equal("UTF-16", document.encoding)
        end
      end

      class WriteTest < self
        def test_utf_16
          xml = <<-EOX.encode("UTF-16LE").force_encoding("ASCII-8BIT")
<?xml version="1.0"?>
<message>Hello world!</message>
EOX
          bom = "\ufeff".encode("UTF-16LE").force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)

          actual_xml = ""
          document.write(actual_xml)
          expected_xml = <<-EOX.chomp.encode("UTF-16BE")
\ufeff<?xml version='1.0' encoding='UTF-16'?>
<message>Hello world!</message>
EOX
          assert_equal(expected_xml, actual_xml)
        end
      end

      class ReadUntilTest < Test::Unit::TestCase
        def test_utf_8
          xml = <<-EOX.force_encoding("ASCII-8BIT")
<?xml version="1.0" encoding="UTF-8"?>
<message testing=">">Hello world!</message>
EOX
          document = REXML::Document.new(xml)
          assert_equal("UTF-8", document.encoding)
          assert_equal(">", REXML::XPath.match(document, "/message")[0].attribute("testing").value)
        end

        def test_utf_16le
          xml = <<-EOX.encode("UTF-16LE").force_encoding("ASCII-8BIT")
<?xml version="1.0" encoding="UTF-16"?>
<message testing=">">Hello world!</message>
EOX
          bom = "\ufeff".encode("UTF-16LE").force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)
          assert_equal("UTF-16", document.encoding)
          assert_equal(">", REXML::XPath.match(document, "/message")[0].attribute("testing").value)
        end

        def test_utf_16be
          xml = <<-EOX.encode("UTF-16BE").force_encoding("ASCII-8BIT")
<?xml version="1.0" encoding="UTF-16"?>
<message testing=">">Hello world!</message>
EOX
          bom = "\ufeff".encode("UTF-16BE").force_encoding("ASCII-8BIT")
          document = REXML::Document.new(bom + xml)
          assert_equal("UTF-16", document.encoding)
          assert_equal(">", REXML::XPath.match(document, "/message")[0].attribute("testing").value)
        end
      end
    end
  end
end
