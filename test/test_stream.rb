# frozen_string_literal: false

require 'rexml/streamlistener'
require 'stringio'

module REXMLTests
  class MyListener
    include REXML::StreamListener
  end


  class StreamTester < Test::Unit::TestCase
    # Submitted by Han Holl
    def test_listener
      data = %Q{<session1 user="han" password="rootWeiler" />\n<session2 user="han" password="rootWeiler" />}

      RequestReader.new( data )
      RequestReader.new( data )
    end

    def test_ticket_49
      source = StringIO.new( <<-EOL )
      <!DOCTYPE foo [
        <!ENTITY ent "replace">
      ]>
      <a>&ent;</a>
      EOL
      REXML::Document.parse_stream(source, MyListener.new)
    end

    def test_ticket_10
      source = StringIO.new( <<-EOL )
      <!DOCTYPE foo [
        <!ENTITY ent "replace">
        <!ATTLIST a
         xmlns:human CDATA #FIXED "http://www.foo.com/human">
        <!ELEMENT bar (#PCDATA)>
        <!NOTATION n1 PUBLIC "-//HM//NOTATION TEST1//EN" 'urn:x-henrikmartensson.org:test5'>
      ]>
      <a/>
      EOL
      listener = MyListener.new
      class << listener
        attr_accessor :events
        def entitydecl( content )
          @events[ :entitydecl ] = true
        end
        def attlistdecl( element_name, attributes, raw_content )
          @events[ :attlistdecl ] = true
        end
        def elementdecl( content )
          @events[ :elementdecl ] = true
        end
        def notationdecl( content )
          @events[ :notationdecl ] = true
        end
      end
      listener.events = {}

      REXML::Document.parse_stream( source, listener )

      assert( listener.events[:entitydecl] )
      assert( listener.events[:attlistdecl] )
      assert( listener.events[:elementdecl] )
      assert( listener.events[:notationdecl] )
    end

    def test_entity
      listener = MyListener.new
      class << listener
        attr_accessor :entities
        def entity(content)
          @entities << content
        end
      end
      listener.entities = []

      source = StringIO.new(<<-XML)
<!DOCTYPE root [
<!ENTITY % ISOLat2
         SYSTEM "http://www.xml.com/iso/isolat2-xml.entities" >
%ISOLat2;
]>
<root/>
      XML
      REXML::Document.parse_stream(source, listener)

      assert_equal(["ISOLat2"], listener.entities)
    end

    def test_entity_replacement
      source = '<!DOCTYPE foo [
      <!ENTITY la "1234">
      <!ENTITY lala "--&la;--">
      <!ENTITY lalal "&la;&la;">
      ]><a><la>&la;</la><lala>&lala;</lala></a>'

      listener = MyListener.new
      class << listener
        attr_accessor :text_values
        def text(text)
          @text_values << text
        end
      end
      listener.text_values = []
      REXML::Document.parse_stream(source, listener)
      assert_equal(["1234", "--1234--"], listener.text_values)
    end

    def test_characters_predefined_entities
      source = '<root><a>&lt;P&gt; &lt;I&gt; &lt;B&gt; Text &lt;/B&gt;  &lt;/I&gt;</a></root>'

      listener = MyListener.new
      class << listener
        attr_accessor :text_value
        def text(text)
          @text_value << text
        end
      end
      listener.text_value = ""
      REXML::Document.parse_stream(source, listener)
      assert_equal("<P> <I> <B> Text </B>  </I>", listener.text_value)
    end
  end

  class EntityExpansionLimitTest < Test::Unit::TestCase
    def setup
      @default_entity_expansion_limit = REXML::Security.entity_expansion_limit
      @default_entity_expansion_text_limit = REXML::Security.entity_expansion_text_limit
    end

    def teardown
      REXML::Security.entity_expansion_limit = @default_entity_expansion_limit
      REXML::Security.entity_expansion_text_limit = @default_entity_expansion_text_limit
    end

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

      assert_raise(RuntimeError.new("entity expansion has grown too large")) do
        REXML::Document.parse_stream(source, MyListener.new)
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

      listener = MyListener.new
      REXML::Security.entity_expansion_limit = 100000
      parser = REXML::Parsers::StreamParser.new( source, listener )
      parser.parse
      assert_equal(11111, parser.entity_expansion_count)

      REXML::Security.entity_expansion_limit = @default_entity_expansion_limit
      parser = REXML::Parsers::StreamParser.new( source, listener )
      assert_raise(RuntimeError.new("number of entity expansions exceeded, processing aborted.")) do
        parser.parse
      end
      assert do
        parser.entity_expansion_count > @default_entity_expansion_limit
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

      listener = MyListener.new
      REXML::Security.entity_expansion_limit = 4
      REXML::Document.parse_stream(source, listener)

      REXML::Security.entity_expansion_limit = 3
      assert_raise(RuntimeError.new("number of entity expansions exceeded, processing aborted.")) do
        REXML::Document.parse_stream(source, listener)
      end
    end

    def test_with_only_default_entities
      member_value = "&lt;p&gt;#{'A' * @default_entity_expansion_text_limit}&lt;/p&gt;"
      source = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<member>
#{member_value}
</member>
      XML

      listener = MyListener.new
      class << listener
        attr_accessor :text_value
        def text(text)
          @text_value << text
        end
      end
      listener.text_value = ""
      REXML::Document.parse_stream(source, listener)

      expected_value = "<p>#{'A' * @default_entity_expansion_text_limit}</p>"
      assert_equal(expected_value, listener.text_value.strip)
      assert do
        listener.text_value.bytesize > @default_entity_expansion_text_limit
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

      listener = MyListener.new
      class << listener
        attr_accessor :text_value
        def text(text)
          @text_value << text
        end
      end
      listener.text_value = ""
      REXML::Security.entity_expansion_text_limit = 90
      REXML::Document.parse_stream(source, listener)

      assert_equal(90, listener.text_value.size)
    end
  end

  # For test_listener
  class RequestReader
    attr_reader :doc
    def initialize(io)
      @stack = []
      @doc = nil
      catch(:fini) do
        REXML::Document.parse_stream(io, self)
        raise IOError
      end
    end
    def tag_start(name, args)
      if @doc
        @stack.push(REXML::Element.new(name, @stack.last))
      else
        @doc = REXML::Document.new("<#{name}/>")
        @stack.push(@doc.root)
      end
      args.each do |attr,val|
        @stack.last.add_attribute(attr, val)
      end
    end
    def tag_end(name, *args)
      @stack.pop
      throw(:fini) if @stack.empty?
    end
    def text(str)
      @stack.last.text = str
    end
    def comment(str)
    end
    def doctype( name, pub_sys, long_name, uri )
    end
    def doctype_end
    end
  end
end
