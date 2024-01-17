# frozen_string_literal: false
require 'test/unit'
require 'rexml/document'

module REXMLTests
  class TestParseEntityDeclaration < Test::Unit::TestCase
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

    def test_empty
      exception = assert_raise(REXML::ParseException) do
        parse(<<-INTERNAL_SUBSET)
<!ENTITY>
        INTERNAL_SUBSET
      end
      assert_equal(<<-DETAIL.chomp, exception.to_s)
Malformed notation declaration: name is missing
Line: 5
Position: 72
Last 80 unconsumed characters:
 <!ENTITY>  ]> <r/>
      DETAIL
    end
  end
end
