# frozen_string_literal: false

require "test/unit"

module REXMLTests
  # Guards the deferred `require "pp"` in REXML::XPathParser#trace. The checks
  # run in a subprocess because this one has pp loaded already.
  class TestRequire < Test::Unit::TestCase
    PP_LOADED = '$LOADED_FEATURES.any? { |f| File.basename(f) == "pp.rb" }'

    def subprocess(script)
      lib = File.join(File.dirname(File.expand_path(__dir__)), "lib")
      IO.popen([RbConfig.ruby, "-I", lib, "-e", script], &:read)
    end

    def test_requiring_document_does_not_load_pp
      assert_equal("false", subprocess("require 'rexml/document'; print #{PP_LOADED}"))
    end

    def test_xpath_works_without_pp
      script = "require 'rexml/document'; " \
               "d = REXML::Document.new('<r><a>x</a><a>y</a></r>'); " \
               "print REXML::XPath.match(d, '//a').map(&:text).join(',')"
      assert_equal("x,y", subprocess(script))
    end

    def test_xpath_does_not_load_pp
      script = "require 'rexml/document'; " \
               "d = REXML::Document.new('<r><a>x</a></r>'); " \
               "REXML::XPath.match(d, '//a'); " \
               "print #{PP_LOADED}"
      assert_equal("false", subprocess(script))
    end
  end
end
