require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestParseCharacterReference < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def test_gt_linear_performance_malformed_character_reference
      seq = [10000, 50000, 100000, 150000, 200000]
      assert_linear_performance(seq, rehearsal: 10) do |n|
        begin
          REXML::Document.new('<test testing="&#' + "0" * n + '"/>')
        rescue
        end
      end
    end
  end
end
