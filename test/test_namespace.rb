# frozen_string_literal: false
require "core_assertions"

module REXMLTests
  class TestNamespace < Test::Unit::TestCase
    include Test::Unit::CoreAssertions
    include Helper::Fixture
    include REXML

    def setup
      @xsa_source = <<-EOL
        <?xml version="1.0"?>
        <?xsl stylesheet="blah.xsl"?>
        <!-- The first line tests the XMLDecl, the second tests PI.
        The next line tests DocType. This line tests comments. -->
        <!DOCTYPE xsa PUBLIC
          "-//LM Garshol//DTD XML Software Autoupdate 1.0//EN//XML"
          "http://www.garshol.priv.no/download/xsa/xsa.dtd">

        <xsa>
          <vendor id="blah">
            <name>Lars Marius Garshol</name>
            <email>larsga@garshol.priv.no</email>
            <url>http://www.stud.ifi.uio.no/~lmariusg/</url>
          </vendor>
        </xsa>
      EOL
    end

    def test_xml_namespace
      xml = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<root xmlns:xml="http://www.w3.org/XML/1998/namespace" />
XML
      document = Document.new(xml)
      assert_equal("http://www.w3.org/XML/1998/namespace",
                   document.root.namespace("xml"))
    end

    def test_deep_element_namespace_linear
      omit('Recursion too deep on JRuby') if RUBY_ENGINE == "jruby"

      max_depth = 3000
      xml = <<~XML
        <root xmlns="one">#{'<a>' * max_depth + '</a>' * max_depth}</root>
      XML
      doc = Document.new(xml)
      prepare_element = ->(depth) do
        node = doc.root
        depth.times { node = node.first }
        node || raise
      end

      assert_linear_performance([30, 100, 300, 1000, 3000], rehearsal: 10) do |depth|
        elem = prepare_element.call(depth)
        elem.namespace
      end
    end
  end
end
