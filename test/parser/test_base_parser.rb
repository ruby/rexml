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
  end
end
