# frozen_string_literal: false

require "pp"

require_relative 'namespace'
require_relative 'xmltokens'
require_relative 'attribute'
require_relative 'parsers/xpathparser'

module REXML
  module DClonable
    refine Object do
      # provides a unified +clone+ operation, for REXML::XPathParser
      # to use across multiple Object types
      def dclone
        clone
      end
    end
    refine Symbol do
      # provides a unified +clone+ operation, for REXML::XPathParser
      # to use across multiple Object types
      def dclone ; self ; end
    end
    refine Integer do
      # provides a unified +clone+ operation, for REXML::XPathParser
      # to use across multiple Object types
      def dclone ; self ; end
    end
    refine Float do
      # provides a unified +clone+ operation, for REXML::XPathParser
      # to use across multiple Object types
      def dclone ; self ; end
    end
    refine Array do
      # provides a unified +clone+ operation, for REXML::XPathParser
      # to use across multiple Object+ types
      def dclone
        klone = self.clone
        klone.clear
        self.each{|v| klone << v.dclone}
        klone
      end
    end
  end
end

using REXML::DClonable

module REXML
  # You don't want to use this class.  Really.  Use XPath, which is a wrapper
  # for this class.  Believe me.  You don't want to poke around in here.
  # There is strange, dark magic at work in this code.  Beware.  Go back!  Go
  # back while you still can!
  class XPathParser
    include XMLTokens
    LITERAL    = /^'([^']*)'|^"([^"]*)"/u

    DEBUG = (ENV["REXML_XPATH_PARSER_DEBUG"] == "true")

    def initialize(strict: false)
      @debug = DEBUG
      @parser = REXML::Parsers::XPathParser.new
      @namespaces = nil
      @variables = {}
      @nest = 0
      @strict = strict
    end

    def namespaces=( namespaces={} )
      Functions::namespace_context = namespaces
      @namespaces = namespaces
    end

    def variables=( vars={} )
      Functions::variables = vars
      @variables = vars
    end

    def parse path, node
      path_stack = @parser.parse( path )
      if node.is_a?(Array)
        Kernel.warn("REXML::XPath.each, REXML::XPath.first, REXML::XPath.match dropped support for nodeset...", uplevel: 1)
        return [] if node.empty?
        node = node.first
      end

      document = node.document
      if document
        document.__send__(:enable_cache) do
          match( path_stack, node )
        end
      else
        match( path_stack, node )
      end
    end

    def get_first path, node
      path_stack = @parser.parse( path )
      first( path_stack, node )
    end

    def predicate path, node
      path_stack = @parser.parse( path )
      match( path_stack, node )
    end

    def []=( variable_name, value )
      @variables[ variable_name ] = value
    end


    # Performs a depth-first (document order) XPath search, and returns the
    # first match.  This is the fastest, lightest way to return a single result.
    #
    # FIXME: This method is incomplete!
    def first( path_stack, node )
      return nil if path.size == 0

      case path[0]
      when :document
        # do nothing
        first( path[1..-1], node )
      when :child
        for c in node.children
          r = first( path[1..-1], c )
          return r if r
        end
      when :qname
        name = path[2]
        if node.name == name
          return node if path.size == 3
          first( path[3..-1], node )
        else
          nil
        end
      when :descendant_or_self
        r = first( path[1..-1], node )
        return r if r
        for c in node.children
          r = first( path, c )
          return r if r
        end
      when :node
        first( path[1..-1], node )
      when :any
        first( path[1..-1], node )
      else
        nil
      end
    end


    def match(path_stack, node)
      nodeset = [node]
      result = expr(path_stack, nodeset)
      case result
      when Array # nodeset
        result.uniq
      else
        [result]
      end
    end

    private
    def strict?
      @strict
    end

    # Returns a String namespace for a node, given a prefix
    # The rules are:
    #
    #  1. Use the supplied namespace mapping first.
    #  2. If no mapping was supplied, use the context node to look up the namespace
    def get_namespace( node, prefix )
      if @namespaces
        @namespaces[prefix] || ''
      else
        return node.namespace( prefix ) if node.node_type == :element
        ''
      end
    end


    # Expr takes a stack of path elements and a set of nodes (either a Parent
    # or an Array and returns an Array of matching nodes
    def expr( path_stack, nodeset, context=nil )
      enter(:expr, path_stack, nodeset) if @debug
      return nodeset if path_stack.length == 0 || nodeset.length == 0
      while path_stack.length > 0
        trace(:while, path_stack, nodeset) if @debug
        if nodeset.length == 0
          path_stack.clear
          return []
        end
        op = path_stack.shift
        case op
        when :document
          nodeset = [nodeset.first.root_node]
        when :self
          nodeset = step(path_stack) do
            [nodeset]
          end
        when :child
          nodeset = step(path_stack) do
            child(nodeset)
          end
        when :literal
          trace(:literal, path_stack, nodeset) if @debug
          return path_stack.shift
        when :attribute
          nodeset = step(path_stack, any_type: :attribute) do
            nodeset.map do |node|
              next unless node.node_type == :element
              attributes = node.attributes
              next if attributes.empty?
              attributes.each_attribute.to_a
            end.compact
          end
        when :namespace
          warn 'Namespace axis is not supported in REXML::XPathParser', uplevel: 1
          # TODO: We need to create NamespaceNode class to support this feature
          nodeset = step(path_stack) { [] }
        when :parent
          nodeset = step(path_stack) do
            nodesets = []
            nodeset.each do |node|
              if node.node_type == :attribute
                parent = node.element
              else
                parent = node.parent
              end
              nodesets << [parent] if parent
            end
            nodesets
          end
        when :ancestor
          nodeset = step(path_stack, axis_order: :reverse) do
            nodesets = []
            # new_nodes = {}
            nodeset.each do |node|
              new_nodeset = []
              while node.parent
                node = node.parent
                # next if new_nodes.key?(node)
                new_nodeset << node
                # new_nodes[node] = true
              end
              nodesets << new_nodeset unless new_nodeset.empty?
            end
            nodesets
          end
        when :ancestor_or_self
          nodeset = step(path_stack, axis_order: :reverse) do
            nodesets = []
            # new_nodes = {}
            nodeset.each do |node|
              next unless node.node_type == :element
              new_nodeset = [node]
              # new_nodes[node] = true
              while node.parent
                node = node.parent
                # next if new_nodes.key?(node)
                new_nodeset << node
                # new_nodes[node] = true
              end
              nodesets << new_nodeset unless new_nodeset.empty?
            end
            nodesets
          end
        when :descendant_or_self
          nodeset = step(path_stack) do
            descendant(nodeset, true)
          end
        when :descendant
          nodeset = step(path_stack) do
            descendant(nodeset, false)
          end
        when :following_sibling
          nodeset = step(path_stack) do
            nodeset.map do |node|
              next unless node.respond_to?(:parent)
              next if node.parent.nil?
              all_siblings = node.parent.children
              current_index = all_siblings.index(node)
              following_siblings = all_siblings[(current_index + 1)..-1]
              next if following_siblings.empty?
              following_siblings
            end.compact
          end
        when :preceding_sibling
          nodeset = step(path_stack, axis_order: :reverse) do
            nodeset.map do |node|
              next unless node.respond_to?(:parent)
              next if node.parent.nil?
              all_siblings = node.parent.children
              current_index = all_siblings.index(node)
              preceding_siblings = all_siblings[0, current_index].reverse
              next if preceding_siblings.empty?
              preceding_siblings
            end.compact
          end
        when :preceding
          nodeset = step(path_stack, axis_order: :reverse) do
            nodeset.map do |node|
              preceding(node)
            end
          end
        when :following
          nodeset = step(path_stack) do
            nodeset.map do |node|
              following(node)
            end
          end
        when :variable
          var_name = path_stack.shift
          return @variables[var_name]

        when :eq, :neq, :lt, :lteq, :gt, :gteq
          left = expr( path_stack.shift, nodeset.dup, context )
          right = expr( path_stack.shift, nodeset.dup, context )
          res = equality_relational_compare( left, op, right )
          trace(op, left, right, res) if @debug
          return res

        when :or
          left = expr(path_stack.shift, nodeset.dup, context)
          return true if Functions.boolean(left)
          right = expr(path_stack.shift, nodeset.dup, context)
          return Functions.boolean(right)

        when :and
          left = expr(path_stack.shift, nodeset.dup, context)
          return false unless Functions.boolean(left)
          right = expr(path_stack.shift, nodeset.dup, context)
          return Functions.boolean(right)

        when :div, :mod, :mult, :plus, :minus
          left = expr(path_stack.shift, nodeset, context)
          right = expr(path_stack.shift, nodeset, context)
          left = Functions::number(left)
          right = Functions::number(right)
          case op
          when :div
            return left / right
          when :mod
            return left % right
          when :mult
            return left * right
          when :plus
            return left + right
          when :minus
            return left - right
          else
            raise "[BUG] Unexpected operator: <#{op.inspect}>"
          end
        when :union
          left = expr( path_stack.shift, nodeset, context )
          right = expr( path_stack.shift, nodeset, context )
          return (left | right)
        when :neg
          res = expr( path_stack, nodeset, context )
          return -Functions.number(res)
        when :not
        when :function
          func_name = path_stack.shift.tr('-','_')
          arguments = path_stack.shift

          if nodeset.size != 1
            message = "[BUG] Node set size must be 1 for function call: "
            message += "<#{func_name}>: <#{nodeset.inspect}>: "
            message += "<#{arguments.inspect}>"
            raise message
          end

          node = nodeset.first
          if context
            target_context = context
          else
            target_context = {:size => nodeset.size}
            target_context[:node]  = node
            target_context[:position] = 1
          end
          args = arguments.dclone.collect do |arg|
            result = expr(arg, nodeset, target_context)
            result
          end
          Functions.context = target_context
          return Functions.send(func_name, *args)
        when :group
          sub_expression = path_stack.shift
          result = expr(sub_expression, nodeset, context)
          if result.is_a?(Array)
            # If result is a nodeset, apply following predicates
            path_stack.unshift(:node)
            nodeset = step(path_stack) do
              [result]
            end
          else
            return result
          end
        else
          raise "[BUG] Unexpected path: <#{op.inspect}>: <#{path_stack.inspect}>"
        end
      end # while
      return nodeset
    ensure
      leave(:expr, path_stack, nodeset) if @debug
    end

    def step(path_stack, any_type: :element, axis_order: :forward)
      nodesets = yield
      begin
        enter(:step, path_stack, nodesets) if @debug
        nodesets = node_test(path_stack, nodesets, any_type: any_type)
        while path_stack[0] == :predicate
          path_stack.shift # :predicate
          predicate_expression = path_stack.shift.dclone
          nodesets = evaluate_predicate(predicate_expression, nodesets)
        end
        if nodesets.size == 1
          new_nodeset = axis_order == :forward ? nodesets.first : nodesets.first.reverse
        else
          nodes = Set.new.compare_by_identity
          nodesets.each do |nodeset|
            nodeset.each do |node|
              nodes << node
            end
          end
          new_nodeset = sort(nodes.to_a)
        end
        new_nodeset
      ensure
        leave(:step, path_stack, new_nodeset) if @debug
      end
    end

    def node_test(path_stack, nodesets, any_type: :element)
      enter(:node_test, path_stack, nodesets) if @debug
      operator = path_stack.shift
      case operator
      when :qname
        prefix = path_stack.shift
        name = path_stack.shift
        new_nodesets = nodesets.collect do |nodeset|
          nodeset.select do |node|
            case node.node_type
            when :element
              if prefix.nil?
                node.name == name
              elsif prefix.empty?
                if strict?
                  node.name == name and node.namespace == ""
                else
                  node.name == name and node.namespace == get_namespace(node, prefix)
                end
              else
                node.name == name and node.namespace == get_namespace(node, prefix)
              end
            when :attribute
              if prefix.nil?
                node.name == name
              elsif prefix.empty?
                node.name == name and node.namespace == ""
              else
                node.name == name and node.namespace == get_namespace(node.element, prefix)
              end
            else
              false
            end
          end
        end
      when :namespace
        prefix = path_stack.shift
        new_nodesets = nodesets.collect do |nodeset|
          nodeset.select do |node|
            case node.node_type
            when :element
              namespaces = @namespaces || node.namespaces
              node.namespace == namespaces[prefix]
            when :attribute
              namespaces = @namespaces || node.element.namespaces
              node.namespace == namespaces[prefix]
            else
              false
            end
          end
        end
      when :any
        new_nodesets = nodesets.collect do |nodeset|
          nodeset.select do |node|
            node.node_type == any_type
          end
        end
      when :comment
        new_nodesets = nodesets.collect do |nodeset|
          nodeset.select do |node|
            node.node_type == :comment
          end
        end
      when :text
        new_nodesets = nodesets.collect do |nodeset|
          nodeset.select do |node|
            node.node_type == :text
          end
        end
      when :processing_instruction
        target = path_stack.shift
        new_nodesets = nodesets.collect do |nodeset|
          nodeset.select do |node|
            (node.node_type == :processing_instruction) and
              (target.empty? or (node.target == target))
          end
        end
      when :node
        new_nodesets = nodesets
      else
        message = "[BUG] Unexpected node test: " +
          "<#{operator.inspect}>: <#{path_stack.inspect}>"
        raise message
      end
      new_nodesets
    ensure
      leave(:node_test, path_stack, new_nodesets) if @debug
    end

    def evaluate_predicate(expression, nodesets)
      enter(:predicate, expression, nodesets) if @debug
      new_nodesets = nodesets.collect do |nodeset|
        new_nodeset = []
        subcontext = { :size => nodeset.size }
        nodeset.each.with_index(1) do |node, position|
          subcontext[:node] = node
          subcontext[:position] = position
          result = expr(expression.dclone, [node], subcontext)
          trace(:predicate_evaluate, expression, node, subcontext, result) if @debug
          if result.kind_of? Numeric
            if result == position
              new_nodeset << node
            end
          elsif result.instance_of? Array
            if result.size > 0
              new_nodeset << node
            end
          else
            if result
              new_nodeset << node
            end
          end
        end
        new_nodeset
      end
      new_nodesets
    ensure
      leave(:predicate, new_nodesets) if @debug
    end

    def trace(*args)
      indent = "  " * @nest
      PP.pp(args, "").each_line do |line|
        puts("#{indent}#{line}")
      end
    end

    def enter(tag, *args)
      trace(:enter, tag, *args)
      @nest += 1
    end

    def leave(tag, *args)
      @nest -= 1
      trace(:leave, tag, *args)
    end

    # Reorders an array of nodes so that they are in document order
    # It tries to do this efficiently.
    #
    # FIXME: I need to get rid of this, but the issue is that most of the XPath
    # interpreter functions as a filter, which means that we lose context going
    # in and out of function calls.  If I knew what the index of the nodes was,
    # I wouldn't have to do this.  Maybe add a document IDX for each node?
    # Problems with mutable documents.  Or, rewrite everything.
    def sort(array_of_nodes)
      new_arry = []
      array_of_nodes.each { |node|
        node_idx = []
        np = node.node_type == :attribute ? node.element : node
        while np.parent and np.parent.node_type == :element
          node_idx << np.parent.index( np )
          np = np.parent
        end
        new_arry << [ node_idx.reverse, node ]
      }
      ordered = new_arry.sort_by do |index, node|
        index
      end
      ordered.collect do |_index, node|
        node
      end
    end

    def descendant(nodeset, include_self)
      nodesets = []
      nodeset.each do |node|
        new_nodeset = []
        new_nodes = {}
        descendant_recursive(node, new_nodeset, new_nodes, include_self)
        nodesets << new_nodeset unless new_nodeset.empty?
      end
      nodesets
    end

    def descendant_recursive(node, new_nodeset, new_nodes, include_self)
      if include_self
        return if new_nodes.key?(node)
        new_nodeset << node
        new_nodes[node] = true
      end

      node_type = node.node_type
      if node_type == :element or node_type == :document
        node.children.each do |child|
          descendant_recursive(child, new_nodeset, new_nodes, true)
        end
      end
    end

    # Builds a nodeset of all of the preceding nodes of the supplied node,
    # in reverse document order
    # preceding:: includes every element in the document that precedes this node,
    # except for ancestors
    def preceding(node)
      ancestors = []
      parent = node.parent
      while parent
        ancestors << parent
        parent = parent.parent
      end

      precedings = []
      preceding_node = preceding_node_of(node)
      while preceding_node
        if ancestors.include?(preceding_node)
          ancestors.delete(preceding_node)
        else
          precedings << preceding_node
        end
        preceding_node = preceding_node_of(preceding_node)
      end
      precedings
    end

    def preceding_node_of( node )
      psn = node.previous_sibling_node
      if psn.nil?
        if node.parent.nil? or node.parent.class == Document
          return nil
        end
        return node.parent
        #psn = preceding_node_of( node.parent )
      end
      while psn and psn.kind_of? Element and psn.children.size > 0
        psn = psn.children[-1]
      end
      psn
    end

    def following(node)
      followings = []
      following_node = next_sibling_node(node)
      while following_node
        followings << following_node
        following_node = following_node_of(following_node)
      end
      followings
    end

    def following_node_of( node )
      return node.children[0] if node.kind_of?(Element) and node.children.size > 0

      next_sibling_node(node)
    end

    def next_sibling_node(node)
      psn = node.next_sibling_node
      while psn.nil?
        return nil if node.parent.nil? or node.parent.class == Document
        node = node.parent
        psn = node.next_sibling_node
      end
      psn
    end

    def child(nodeset)
      nodesets = []
      nodeset.each do |node|
        node_type = node.node_type
        # trace(:child, node_type, node)
        case node_type
        when :element
          nodesets << node.children
        when :document
          new_nodeset = node.children.reject do |child|
            case child
            when XMLDecl, Text
              true # Ignore
            end
          end
          nodesets << new_nodeset unless new_nodeset.empty?
        end
      end
      nodesets
    end

    def norm b
      case b
      when true, false
        b
      when 'true', 'false'
        Functions::boolean( b )
      when /^\d+(\.\d+)?$/, Numeric
        Functions::number( b )
      else
        Functions::string( b )
      end
    end

    def equality_relational_compare(set1, op, set2)
      if set1.kind_of? Array and set2.kind_of? Array
        # If both objects to be compared are node-sets, then the
        # comparison will be true if and only if there is a node in the
        # first node-set and a node in the second node-set such that the
        # result of performing the comparison on the string-values of
        # the two nodes is true.
        set1.product(set2).any? do |node1, node2|
          node_string1 = Functions.string(node1)
          node_string2 = Functions.string(node2)
          compare(node_string1, op, node_string2)
        end
      elsif set1.kind_of? Array or set2.kind_of? Array
        # If one is nodeset and other is number, compare number to each item
        # in nodeset s.t. number op number(string(item))
        # If one is nodeset and other is string, compare string to each item
        # in nodeset s.t. string op string(item)
        # If one is nodeset and other is boolean, compare boolean to each item
        # in nodeset s.t. boolean op boolean(item)
        if set1.kind_of? Array
          a = set1
          b = set2
        else
          a = set2
          b = set1
        end

        case b
        when true, false
          a.any? do |node|
            compare(Functions.boolean(node), op, b)
          end
        when Numeric
          a.any? do |node|
            compare(Functions.number(node), op, b)
          end
        when /\A\d+(\.\d+)?\z/
          b = Functions.number(b)
          a.any? do |node|
            compare(Functions.number(node), op, b)
          end
        else
          b = Functions::string(b)
          a.any? do |node|
            compare(Functions::string(node), op, b)
          end
        end
      else
        # If neither is nodeset,
        #   If op is = or !=
        #     If either boolean, convert to boolean
        #     If either number, convert to number
        #     Else, convert to string
        #   Else
        #     Convert both to numbers and compare
        compare(set1, op, set2)
      end
    end

    def value_type(value)
      case value
      when true, false
        :boolean
      when Numeric
        :number
      when String
        :string
      else
        raise "[BUG] Unexpected value type: <#{value.inspect}>"
      end
    end

    def normalize_compare_values(a, operator, b)
      a_type = value_type(a)
      b_type = value_type(b)
      case operator
      when :eq, :neq
        if a_type == :boolean or b_type == :boolean
          a = Functions.boolean(a) unless a_type == :boolean
          b = Functions.boolean(b) unless b_type == :boolean
        elsif a_type == :number or b_type == :number
          a = Functions.number(a) unless a_type == :number
          b = Functions.number(b) unless b_type == :number
        else
          a = Functions.string(a) unless a_type == :string
          b = Functions.string(b) unless b_type == :string
        end
      when :lt, :lteq, :gt, :gteq
        a = Functions.number(a) unless a_type == :number
        b = Functions.number(b) unless b_type == :number
      else
        message = "[BUG] Unexpected compare operator: " +
          "<#{operator.inspect}>: <#{a.inspect}>: <#{b.inspect}>"
        raise message
      end
      [a, b]
    end

    def compare(a, operator, b)
      a, b = normalize_compare_values(a, operator, b)
      case operator
      when :eq
        a == b
      when :neq
        a != b
      when :lt
        a < b
      when :lteq
        a <= b
      when :gt
        a > b
      when :gteq
        a >= b
      else
        message = "[BUG] Unexpected compare operator: " +
          "<#{operator.inspect}>: <#{a.inspect}>: <#{b.inspect}>"
        raise message
      end
    end
  end
end
