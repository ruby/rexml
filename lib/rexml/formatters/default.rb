# frozen_string_literal: false

module REXML
  module Formatters
    class Default
      # Prints out the XML document with no formatting -- except if ie_hack is
      # set.
      #
      # ie_hack::
      #   If set to true, then inserts whitespace before the close of an empty
      #   tag, so that IE's bad XML parser doesn't choke.
      def initialize( ie_hack=false )
        @ie_hack = ie_hack
      end

      # Writes the node to some output.
      #
      # node::
      #   The node to write
      # output::
      #   A class implementing <TT>&lt;&lt;</TT>.  Pass in an Output object to
      #   change the output encoding.
      def write( node, output )
        case node

        when Document
          if node.xml_decl.encoding != 'UTF-8' && !output.kind_of?(Output)
            output = Output.new( output, node.xml_decl.encoding )
          end
          write_document( node, output )

        when Element
          write_element( node, output )

        when Declaration, ElementDecl, NotationDecl, ExternalEntity, Entity,
             Attribute, AttlistDecl
          node.write( output,-1 )

        when Instruction
          write_instruction( node, output )

        when DocType, XMLDecl
          node.write( output )

        when Comment
          write_comment( node, output )

        when CData
          write_cdata( node, output )

        when Text
          write_text( node, output )

        else
          raise Exception.new("XML FORMATTING ERROR")

        end
      end

      protected
      def write_document( node, output )
        node.children.each { |child| write( child, output ) }
      end

      # Descendants are walked with an explicit stack instead of recursion so
      # that a deeply nested document doesn't exhaust the machine stack. A
      # String on the stack is an end tag waiting to be written.
      def write_element( node, output )
        stack = [node]
        until stack.empty?
          current = stack.pop
          case current
          when String
            output << current
          when Element
            output << "<#{current.expanded_name}"
            write_element_attributes( current, output )
            children = current.children
            if children.empty?
              output << " " if @ie_hack
              output << "/>"
            else
              output << ">"
              stack << "</#{current.expanded_name}>"
              stack.concat(children.reverse)
            end
          else
            write( current, output )
          end
        end
      end

      def write_text( node, output )
        output << node.to_s()
      end

      def write_comment( node, output )
        output << Comment::START
        output << node.to_s
        output << Comment::STOP
      end

      def write_cdata( node, output )
        output << CData::START
        output << node.to_s
        output << CData::STOP
      end

      def write_instruction( node, output )
        output << Instruction::START
        output << node.target
        content = node.content
        if content
          output << ' '
          output << content
        end
        output << Instruction::STOP
      end

      private
      def write_element_attributes( node, output )
        return if node.attributes.empty?
        node.attributes.to_a.map { |a|
          Hash === a ? a.values : a
        }.flatten.sort_by {|attr| attr.name}.each do |attr|
          output << " "
          attr.write( output )
        end
      end
    end
  end
end
