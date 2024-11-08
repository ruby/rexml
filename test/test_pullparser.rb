# frozen_string_literal: false

require 'rexml/parsers/pullparser'

module REXMLTests
  class PullParserTester < Test::Unit::TestCase
    include REXML
    def test_basics
      source = '<?xml version="1.0"?>
      <!DOCTYPE blah>
      <a>foo &lt;<b attribute="value">bar</b> nooo</a>'
      parser = REXML::Parsers::PullParser.new(source)
      res = { :text=>0 }
      until parser.empty?
        results = parser.pull
        res[ :xmldecl ] = true if results.xmldecl?
        res[ :doctype ] = true if results.doctype?
        res[ :a ] = true if results.start_element? and results[0] == 'a'
        if results.start_element? and results[0] == 'b'
          res[ :b ] = true
          assert_equal 'value', results[1]['attribute']
        end
        res[ :text ] += 1 if results.text?
      end
      [ :xmldecl, :doctype, :a, :b ].each { |tag|
        assert res[tag] , "#{tag} wasn't processed"
      }
      assert_equal 4, res[ :text ]
    rescue ParseException
      puts $!
    end

    def test_bad_document
      source = "<a><b></a>"
      parser = REXML::Parsers::PullParser.new(source)
      assert_raise(ParseException, "Parsing should have failed") {
        parser.pull while parser.has_next?
      }
    end

    def test_entity_replacement
      source = '<!DOCTYPE foo [
      <!ENTITY la "1234">
      <!ENTITY lala "--&la;--">
      <!ENTITY lalal "&la;&la;">
      ]><a><la>&la;</la><lala>&lala;</lala></a>'
      pp = REXML::Parsers::PullParser.new( source )
      el_name = ''
      while pp.has_next?
        event = pp.pull
        case event.event_type
        when :start_element
          el_name = event[0]
        when :text
          case el_name
          when 'la'
            assert_equal('1234', event[1])
          when 'lala'
            assert_equal('--1234--', event[1])
          end
        end
      end
    end

    def test_character_references
      source = '<root><a>&#65;</a><b>&#x42;</b></root>'
      parser = REXML::Parsers::PullParser.new( source )

      events = {}
      element_name = ''
      while parser.has_next?
        event = parser.pull
        case event.event_type
        when :start_element
          element_name = event[0]
        when :text
          events[element_name] = event[1]
        end
      end

      assert_equal('A', events['a'])
      assert_equal("B", events['b'])
    end

    def test_text_entity_references
      source = '<root><a>&lt;P&gt; &lt;I&gt; &lt;B&gt; Text &lt;/B&gt;  &lt;/I&gt;</a></root>'
      parser = REXML::Parsers::PullParser.new( source )

      events = []
      while parser.has_next?
        event = parser.pull
        case event.event_type
        when :text
          events << event[1]
        end
      end

      assert_equal(["<P> <I> <B> Text </B>  </I>"], events)
    end

    def test_text_content_with_line_breaks
      source = "<root><a>A</a><b>B\n</b><c>C\r\n</c></root>"
      parser = REXML::Parsers::PullParser.new( source )

      events = {}
      element_name = ''
      while parser.has_next?
        event = parser.pull
        case event.event_type
        when :start_element
          element_name = event[0]
        when :text
          events[element_name] = event[1]
        end
      end

      assert_equal('A', events['a'])
      assert_equal("B\n", events['b'])
      assert_equal("C\n", events['c'])
    end

    def test_peek_unshift
      source = "<a><b/></a>"
      REXML::Parsers::PullParser.new(source)
      # FINISH ME!
    end

    def test_inspect
      xml =  '<a id="1"><b id="2">Hey</b></a>'
      parser = Parsers::PullParser.new( xml )
      while parser.has_next?
        pull_event = parser.pull
        if pull_event.start_element?
          peek = parser.peek()
          peek.inspect
        end
      end
    end

    def test_peek
      xml =  '<a id="1"><b id="2">Hey</b></a>'
      parser = Parsers::PullParser.new( xml )
      names = %w{ a b }
      while parser.has_next?
        pull_event = parser.pull
        if pull_event.start_element?
          assert_equal( :start_element, pull_event.event_type )
          assert_equal( names.shift, pull_event[0] )
          if names[0] == 'b'
            peek = parser.peek()
            assert_equal( :start_element, peek.event_type )
            assert_equal( names[0], peek[0] )
          end
        end
      end
      assert_equal( 0, names.length )
    end

    def test_reset
      xml_chunks = [
        "<message>First valid and complete message</message>",
        "<message>Second valid and complete message</message>",
        "<message>Third valid and complete message</message>"
      ]

      messages = []

      IO.pipe do |reader, writer|
        xml_chunks.each do |chunk|
          writer.write(chunk)
        end
        writer.close

        parser = REXML::Parsers::PullParser.new(reader)
        while parser.has_next?
          parser.pull
          message_text = parser.pull
          messages << message_text[0]
          parser.pull
          parser.reset
        end
      end

      assert_equal(
        messages,
        ["First valid and complete message",
         "Second valid and complete message",
         "Third valid and complete message"]
      )
    end

    class EntityExpansionLimitTest < Test::Unit::TestCase
      class GeneralEntityTest < self
        def test_have_value
          source = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE member [
  <!ENTITY a "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">
  <!ENTITY b "&c;&c;&c;&c;&c;&c;&c;&c;&c;&c;">
  <!ENTITY c "&d;&d;&d;&d;&d;&d;&d;&d;&d;&d;">
  <!ENTITY d "&e;&e;&e;&e;&e;&e;&e;&e;&e;&e;">
  <!ENTITY e "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">
]>
<member>
&a;
</member>
          XML

          parser = REXML::Parsers::PullParser.new(source)
          assert_raise(RuntimeError.new("entity expansion has grown too large")) do
            while parser.has_next?
              parser.pull
            end
          end
        end

        def test_empty_value
          source = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE member [
  <!ENTITY a "&b;&b;&b;&b;&b;&b;&b;&b;&b;&b;">
  <!ENTITY b "&c;&c;&c;&c;&c;&c;&c;&c;&c;&c;">
  <!ENTITY c "&d;&d;&d;&d;&d;&d;&d;&d;&d;&d;">
  <!ENTITY d "&e;&e;&e;&e;&e;&e;&e;&e;&e;&e;">
  <!ENTITY e "">
]>
<member>
&a;
</member>
          XML

          parser = REXML::Parsers::PullParser.new(source)
          parser.entity_expansion_limit = 100000
          while parser.has_next?
            parser.pull
          end
          assert_equal(11111, parser.entity_expansion_count)

          parser = REXML::Parsers::PullParser.new(source)
          assert_raise(RuntimeError.new("number of entity expansions exceeded, processing aborted.")) do
            while parser.has_next?
              parser.pull
            end
          end
          assert do
            parser.entity_expansion_count > REXML::Security.entity_expansion_limit
          end
        end

        def test_with_default_entity
          source = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE member [
  <!ENTITY a "a">
  <!ENTITY a2 "&a; &a;">
]>
<member>
&a;
&a2;
&lt;
</member>
          XML

          parser = REXML::Parsers::PullParser.new(source)
          parser.entity_expansion_limit = 4
          while parser.has_next?
            parser.pull
          end

          parser = REXML::Parsers::PullParser.new(source)
          parser.entity_expansion_limit = 3
          assert_raise(RuntimeError.new("number of entity expansions exceeded, processing aborted.")) do
            while parser.has_next?
              parser.pull
            end
          end
        end

        def test_with_only_default_entities
          member_value = "&lt;p&gt;#{'A' * REXML::Security.entity_expansion_text_limit}&lt;/p&gt;"
          source = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<member>
#{member_value}
</member>
          XML

          parser = REXML::Parsers::PullParser.new(source)
          events = {}
          element_name = ''
          while parser.has_next?
            event = parser.pull
            case event.event_type
            when :start_element
              element_name = event[0]
            when :text
              events[element_name] = event[1]
            end
          end

          expected_value = "<p>#{'A' * REXML::Security.entity_expansion_text_limit}</p>"
          assert_equal(expected_value, events['member'].strip)
          assert_equal(0, parser.entity_expansion_count)
          assert do
            events['member'].bytesize > REXML::Security.entity_expansion_text_limit
          end
        end

        def test_entity_expansion_text_limit
          source = <<-XML
<!DOCTYPE member [
  <!ENTITY a "&b;&b;&b;">
  <!ENTITY b "&c;&d;&e;">
  <!ENTITY c "xxxxxxxxxx">
  <!ENTITY d "yyyyyyyyyy">
  <!ENTITY e "zzzzzzzzzz">
]>
<member>&a;</member>
          XML

          parser = REXML::Parsers::PullParser.new(source)
          parser.entity_expansion_text_limit = 90
          events = {}
          element_name = ''
          while parser.has_next?
            event = parser.pull
            case event.event_type
            when :start_element
              element_name = event[0]
            when :text
              events[element_name] = event[1]
            end
          end
          assert_equal(90, events['member'].size)
        end
      end
    end
  end
end
