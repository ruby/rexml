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

      test("encoding_updated") do
        def @source.n_encoding_updated_called
          @n_encoding_updated_called
        end
        def @source.encoding_updated
          super
          @n_encoding_updated_called ||= 0
          @n_encoding_updated_called += 1
        end
        @source.encoding = "shift-jis"
        assert_equal(1, @source.n_encoding_updated_called)
        @source.encoding = "Shift-JIS"
        assert_equal(1, @source.n_encoding_updated_called)
      end

      test("Encoding") do
        @source.encoding = Encoding::UTF_8
        assert_equal("UTF-8", @source.encoding)
      end
    end
  end
end
