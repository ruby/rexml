# frozen_string_literal: true
require "test/unit"
require "core_assertions"

require "rexml/document"

module REXMLTests
  class TestRactor < Test::Unit::TestCase
    include Test::Unit::CoreAssertions

    def setup
      if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("4.0")
        omit("Ractor is unreliable before Ruby 4.0")
      end
    end

    def test_document
      assert_ractor(<<~'RUBY', require: "rexml/document")
        xml = "<!DOCTYPE root [<!ENTITY g 'Hello'>]>" +
              "<root name='value'><child>&g; &amp; more</child></root>"
        result = Ractor.new(xml) do |source|
          document = REXML::Document.new(source)
          output = +""
          document.write(output)
          [document.root.attributes["name"],
           document.root.elements["child"].text,
           output]
        end.value
        assert_equal(["value",
                      "Hello & more",
                      "<!DOCTYPE root [\n<!ENTITY g \"Hello\">\n]>" +
                      "<root name='value'><child>&g; &amp; more</child></root>"],
                     result)
      RUBY
    end

    def test_xpath
      assert_ractor(<<~'RUBY', require: ["rexml/document", "rexml/xpath"])
        xml = "<league><team id='1'>Aces</team><team id='2'>Bandits</team></league>"
        result = Ractor.new(xml) do |source|
          document = REXML::Document.new(source)
          [REXML::XPath.match(document, "//team/@id").collect(&:value),
           REXML::XPath.first(document, "count(//team)"),
           REXML::XPath.first(document, "//team[@id=$id]", nil, {"id" => "2"}).text]
        end.value
        assert_equal([["1", "2"], 2, "Bandits"], result)
      RUBY
    end

    def test_node_types
      assert_ractor(<<~'RUBY', require: "rexml/document")
        xml = "<?xml version='1.0'?><!-- a comment --><?pi data?>" +
              "<root><![CDATA[<not> & markup]]></root>"
        result = Ractor.new(xml) do |source|
          output = +""
          REXML::Document.new(source).write(output)
          output
        end.value
        assert_equal(xml, result)
      RUBY
    end

    def test_stream_parsers
      requires = ["rexml/parsers/pullparser",
                  "rexml/parsers/sax2parser",
                  "rexml/parsers/streamparser",
                  "rexml/streamlistener"]
      assert_ractor(<<~'RUBY', require: requires)
        class Listener
          include REXML::StreamListener
          attr_reader :names
          def initialize
            @names = []
          end
          def tag_start(name, attributes)
            @names << name
          end
        end

        xml = "<root><child a='1'>text</child></root>"
        result = Ractor.new(xml) do |source|
          pull = REXML::Parsers::PullParser.new(source)
          pull_names = []
          while pull.has_next?
            event = pull.pull
            pull_names << event[0] if event.start_element?
          end

          sax_names = []
          sax = REXML::Parsers::SAX2Parser.new(source)
          sax.listen(:start_element) do |uri, local_name, qname, attributes|
            sax_names << local_name
          end
          sax.parse

          listener = Listener.new
          REXML::Parsers::StreamParser.new(source, listener).parse

          [pull_names, sax_names, listener.names]
        end.value
        assert_equal([["root", "child"]] * 3, result)
      RUBY
    end

    def test_parallel
      assert_ractor(<<~'RUBY', require: ["rexml/document", "rexml/xpath"])
        xml = "<league><team id='1'>Aces</team><team id='2'>Bandits</team></league>"
        ractors = 4.times.collect do
          Ractor.new(xml) do |source|
            10.times.collect do
              document = REXML::Document.new(source)
              REXML::XPath.match(document, "//team").collect(&:text)
            end.uniq
          end
        end
        assert_equal([[["Aces", "Bandits"]]] * 4, ractors.collect(&:value))
      RUBY
    end
  end
end
