require "rexml/source"

module REXMLTests
  class TestSource < Test::Unit::TestCase
    def setup
      @source = REXML::Source.new(+"<root/>")
    end

    sub_test_case("#encoding=") do
      test("String") do
        @source.encoding = "UTF-8"
        assert_equal("UTF-8", @source.encoding)
      end

      test("Encoding") do
        @source.encoding = Encoding::UTF_8
        assert_equal("UTF-8", @source.encoding)
      end
    end
  end
end
