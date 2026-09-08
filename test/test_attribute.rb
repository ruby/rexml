module REXMLTests
  class AttributeTest < Test::Unit::TestCase
    def test_empty_prefix
      error = assert_raise(ArgumentError) do
        REXML::Attribute.new(":x")
      end
      assert_equal("name must be " +
                   "\#{PREFIX}:\#{LOCAL_NAME} or \#{LOCAL_NAME}: <\":x\">",
                   error.message)
    end

    def test_namespace_declaration
      assert_equal(false, REXML::Attribute.new("name").namespace_declaration?)
      assert_equal(false, REXML::Attribute.new("prefix:name").namespace_declaration?)
      assert_equal(false, REXML::Attribute.new("prefix:xmlns").namespace_declaration?)
      assert_equal(true, REXML::Attribute.new("xmlns").namespace_declaration?)
      assert_equal(true, REXML::Attribute.new("xmlns:name").namespace_declaration?)
      # REXML::Attribute.new("xmlns:xmlns") is not tested because it's invalid
    end

    def test_to_string_entity
      document = REXML::Document.new(<<-XML)
<!DOCTYPE root [
  <!ENTITY empty "">
  <!ENTITY a "aaa">
]>
<root/>
      XML
      document.root.add_attribute("attr", "abc aaa")
      assert_equal("<root attr='abc &a;'/>", document.root.to_s)
    end
  end
end
