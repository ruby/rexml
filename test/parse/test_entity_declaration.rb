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

    def test_linear_performance_gt
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        REXML::Document.new('<!DOCTYPE rubynet [<!ENTITY rbconfig.ruby_version "' + '>' * n + '">')
      end
    end
  end
end
