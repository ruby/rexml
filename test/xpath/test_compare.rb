# frozen_string_literal: false

module REXMLTests
  class TestXPathCompare < Test::Unit::TestCase
    def match(xml, xpath)
      document = REXML::Document.new(xml)
      REXML::XPath.match(document, xpath)
    end

    class TestEqual < self
      class TestNodeSet < self
        def test_boolean_true
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child/>
  <child/>
</root>
          XML
          assert_equal([true],
                       match(xml, "/root/child=true()"))
        end

        def test_boolean_false
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
</root>
        XML
          assert_equal([false],
                       match(xml, "/root/child=true()"))
        end

        def test_number_true
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>100</child>
  <child>200</child>
</root>
          XML
          assert_equal([true],
                       match(xml, "/root/child=100"))
        end

        def test_number_false
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>100</child>
  <child>200</child>
</root>
          XML
          assert_equal([false],
                       match(xml, "/root/child=300"))
        end

        def test_string_true
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>text</child>
  <child>string</child>
</root>
          XML
          assert_equal([true],
                       match(xml, "/root/child='string'"))
        end

        def test_string_false
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>text</child>
  <child>string</child>
</root>
          XML
          assert_equal([false],
                       match(xml, "/root/child='nonexistent'"))
        end

        def test_boolean_empty
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
</root>
          XML
          assert_equal([[true], [false]],
                       [
                         match(xml, "/root/child=false()"),
                         match(xml, "false()!=/root/child"),
                       ])
        end

        def test_string_number_like
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>100</child>
</root>
          XML
          assert_equal([[false], [true]],
                       [
                         match(xml, "/root/child='100.0'"),
                         match(xml, "'100'=/root/child"),
                       ])
        end
      end

      class TestBoolean < self
        def test_number_true
          xml = "<root/>"
          assert_equal([true],
                       match(xml, "true()=1"))
        end

        def test_number_false
          xml = "<root/>"
          assert_equal([false],
                       match(xml, "true()=0"))
        end

        def test_string_true
          xml = "<root/>"
          assert_equal([true],
                       match(xml, "true()='string'"))
        end

        def test_string_false
          xml = "<root/>"
          assert_equal([false],
                       match(xml, "true()=''"))
        end
      end

      class TestNumber < self
        def test_string_true
          xml = "<root/>"
          assert_equal([true],
                       match(xml, "1='1'"))
        end

        def test_string_false
          xml = "<root/>"
          assert_equal([false],
                       match(xml, "1='2'"))
        end
      end
    end

    class TestGreaterThan < self
      class TestNodeSet < self
        def test_boolean_truex
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child/>
</root>
          XML
          assert_equal([true],
                       match(xml, "/root/child>false()"))
        end

        def test_boolean_false
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child/>
</root>
        XML
          assert_equal([false],
                       match(xml, "/root/child>true()"))
        end

        def test_number_true
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>100</child>
  <child>200</child>
</root>
          XML
          assert_equal([true],
                       match(xml, "/root/child>199"))
        end

        def test_number_false
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>100</child>
  <child>200</child>
</root>
          XML
          assert_equal([false],
                       match(xml, "/root/child>200"))
        end

        def test_string_true
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>100</child>
  <child>200</child>
</root>
          XML
          assert_equal([true],
                       match(xml, "/root/child>'199'"))
        end

        def test_string_false
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>100</child>
  <child>200</child>
</root>
          XML
          assert_equal([false],
                       match(xml, "/root/child>'200'"))
        end

        def test_boolean_left
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child/>
</root>
          XML
          assert_equal([[false], [true]],
                       [
                         match(xml, "false()>/root/child"),
                         match(xml, "true()>/root/nonexistent"),
                       ])
        end

        def test_number_left
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>200</child>
  <child>300</child>
</root>
          XML
          assert_equal([[false], [true]],
                       [
                         match(xml, "150>/root/child"),
                         match(xml, "250>/root/child"),
                       ])
        end

        def test_string_left
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>200</child>
  <child>300</child>
</root>
          XML
          assert_equal([[false], [true]],
                       [
                         match(xml, "'150'>/root/child"),
                         match(xml, "'250'>/root/child"),
                       ])
        end

        def test_predicate_number_left
          xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <item price="5"/>
  <item price="50"/>
</root>
          XML
          assert_equal(["5"],
                       match(xml, "/root/item[10>@price]").collect {|item| item.attributes["price"]})
        end
      end

      class TestBoolean < self
        def test_string_true
          xml = "<root/>"
          assert_equal([true],
                       match(xml, "true()>'0'"))
        end

        def test_string_false
          xml = "<root/>"
          assert_equal([false],
                       match(xml, "true()>'1'"))
        end
      end

      class TestNumber < self
        def test_boolean_true
          xml = "<root/>"
          assert_equal([true],
                       match(xml, "true()>0"))
        end

        def test_number_false
          xml = "<root/>"
          assert_equal([false],
                       match(xml, "true()>1"))
        end

        def test_string_true
          xml = "<root/>"
          assert_equal([true],
                       match(xml, "1>'0'"))
        end

        def test_string_false
          xml = "<root/>"
          assert_equal([false],
                       match(xml, "1>'1'"))
        end
      end

      class TestString < self
        def test_string_true
          xml = "<root/>"
          assert_equal([true],
                       match(xml, "'1'>'0'"))
        end

        def test_string_false
          xml = "<root/>"
          assert_equal([false],
                       match(xml, "'1'>'1'"))
        end
      end
    end
  end
end
