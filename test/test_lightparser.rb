# frozen_string_literal: false

require 'rexml/parsers/lightparser'

module REXMLTests
  class LightParserTester < Test::Unit::TestCase
    include Helper::Fixture
    include REXML
    def test_parsing
      File.open(fixture_path("documentation.xml")) do |f|
        parser = REXML::Parsers::LightParser.new( f )
        parser.parse
      end
    end
  end
end
