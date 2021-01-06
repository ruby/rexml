# frozen_string_literal: false

module REXMLTests
  class TestIssuezillaParsing < Test::Unit::TestCase
    include Helper::Fixture
    def test_rexml
      doc = File.open(fixture_path("ofbiz-issues-full-177.xml")) do |f|
        REXML::Document.new(f)
      end
      ctr = 1
      doc.root.each_element('//issue') do |issue|
        assert_equal( ctr, issue.elements['issue_id'].text.to_i )
        ctr += 1
      end
    end
  end
end
