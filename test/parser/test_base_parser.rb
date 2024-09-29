# frozen_string_literal: false

require 'rexml/parsers/baseparser'

module REXMLTests
  class BaseParserTester < Test::Unit::TestCase
    def test_large_xml
      large_text = "a" * 100_000
      xml = <<-XML
        <?xml version="1.0"?>
        <root>
          <child>#{large_text}</child>
          <child>#{large_text}</child>
        </root>
      XML

      parser = REXML::Parsers::BaseParser.new(xml)
      while parser.has_next?
        parser.pull
      end

      assert do
        parser.position < xml.bytesize
      end
    end

    def test_attribute_prefixed_by_xml
      xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
          <head>
            <title>XHTML Document</title>
          </head>
          <body>
            <h1>XHTML Document</h1>
            <p xml:lang="ja" lang="ja">For Japanese</p>
          </body>
        </html>
      XML

      parser = REXML::Parsers::BaseParser.new(xml)
      5.times {parser.pull}

      html = parser.pull
      assert_equal([:start_element,
                    "html",
                    {"xmlns" => "http://www.w3.org/1999/xhtml",
                     "xml:lang" => "en",
                     "lang" => "en"}],
                   html)

      15.times {parser.pull}

      p = parser.pull
      assert_equal([:start_element,
                    "p",
                    {"xml:lang" => "ja", "lang" => "ja"}],
                   p)
    end
  end
end
