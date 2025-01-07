# frozen_string_literal: false
require_relative 'pretty'

module REXML
  module Formatters
    # The Transitive formatter writes an XML document that parses to an
    # identical document as the source document.  This means that no extra
    # whitespace nodes are inserted, and whitespace within text nodes is
    # preserved.  Within these constraints, the document is pretty-printed,
    # with whitespace inserted into the metadata to introduce formatting.
    #
    # Note that this is only useful if the original XML is not already
    # formatted.  Since this formatter does not alter whitespace nodes, the
    # results of formatting already formatted XML will be odd.
    class Transitive < REXML::Formatters::Pretty
      def write_text( node, output )
        output << node.to_s()
      end
    end
  end
end
