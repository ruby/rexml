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
      @functions = FunctionsClass.new
      @nest = 0
      @strict = strict
    end

    def namespaces=( namespaces={} )
      @functions.namespace_context = namespaces
      @namespaces = namespaces
    end

    def variables=( vars={} )
      @functions.variables = vars
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
            [:iterate_nodesets, [nodeset]]
          end
        when :child
          nodeset = step(path_stack) do
            [:iterate_nodesets, child(nodeset)]
          end
        when :literal
          trace(:literal, path_stack, nodeset) if @debug
          return path_stack.shift
        when :attribute
          nodeset = step(path_stack, any_type: :attribute) do
            nodesets = nodeset.map do |node|
              next unless node.node_type == :element
              attributes = node.attributes
              next if attributes.empty?
              attributes.each_attribute.to_a
            end.compact
            [:iterate_nodesets, nodesets]
          end
        when :namespace
          warn 'Namespace axis is not supported in REXML::XPathParser', uplevel: 1
          # TODO: We need to create NamespaceNode class to support this feature
          nodeset = step(path_stack) { [:iterate_nodesets, []] }
        when :parent
          nodeset = step(path_stack) do
            parents = Set.new.compare_by_identity
            nodeset.each do |node|
              if node.node_type == :attribute
                parent = node.element
              else
                parent = node.parent
              end
              parents << parent if parent
            end
            [:iterate_nodesets, parents.map {|parent| [parent] }]
          end
        when :ancestor, :ancestor_or_self,
            :descendant, :descendant_or_self,
            :preceding, :preceding_sibling,
            :following, :following_sibling
          nodeset = step(path_stack) do
            [op, nodeset]
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
          return true if @functions.boolean(left)
          right = expr(path_stack.shift, nodeset.dup, context)
          return @functions.boolean(right)

        when :and
          left = expr(path_stack.shift, nodeset.dup, context)
          return false unless @functions.boolean(left)
          right = expr(path_stack.shift, nodeset.dup, context)
          return @functions.boolean(right)

        when :div, :mod, :mult, :plus, :minus
          left = expr(path_stack.shift, nodeset, context)
          right = expr(path_stack.shift, nodeset, context)
          left = @functions.number(left)
          right = @functions.number(right)
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
          return -@functions.number(res)
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
            expr(arg, nodeset, target_context)
          end
          @functions.context = target_context
          return @functions.send(func_name, *args)
        when :group
          sub_expression = path_stack.shift
          result = expr(sub_expression, nodeset, context)
          if result.is_a?(Array)
            # If result is a nodeset, apply following predicates
            path_stack.unshift(:node)
            nodeset = step(path_stack) do
              [:iterate_nodesets, [result]]
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

    # Determines if a predicate expression is dependent on the position of nodes.
    # Returns false if the expression is guaranteed to be position-independent.
    # Returns true if the expression might be position-dependent.
    def position_dependent?(predicate_expr)
      # expressions that contain position-dependent functions are position-dependent.
      return true if calls_position_dependent_function?(predicate_expr)

      # Even if expression is followed by path steps, the analysis of
      # position dependency is the same as the expression itself.
      case predicate_expr[0]
      when :union, :or, :and, :eq, :neq, :lt, :lteq, :gt, :gteq, :not
        # Expressions that don't evaluate to a number are position independent
        # if it doesn't contain position-dependent functions.
        false
      when :div, :mod, :mult, :plus, :minus, :neg
        # expressions that return number. eg. `[@attr + 1]`
        true
      when :literal
        # Numeric literal is position dependent. String and boolean literal is useless
        # and not worth optimizing
        true
      when :variable
        # A variable could resolve to a number at runtime.
        # It's possible to optimize this by checking the actual value of the variable.
        true
      when :function
        # functions that return number is position dependent. eg. `[position() = string-length(@attr)]`
        %w[number ceiling round floor string-length sum count].include?(predicate_expr[1])
      when :group
        position_dependent?(predicate_expr[1])
      when :descendant, :descendant_or_self, :ancestor, :ancestor_or_self,
           :following, :following_sibling, :preceding, :preceding_sibling,
           :document, :child, :self, :parent, :attribute, :namespace
        # paths are position independent. `foo[path[1]]` doesn't depend on the position of `foo`
        false
      else
        # Every other unhandled expressions are treated position dependent for safety
        true
      end
    end

    # Recursively checks if the expression contains position-dependent functions such as position() or last()
    def calls_position_dependent_function?(expr)
      return false unless Array === expr
      return true if expr[0] == :function && (expr[1] == 'position' || expr[1] == 'last')
      expr.any? {|part| calls_position_dependent_function?(part) }
    end

    # Detects simple position-based predicates that can be optimized in axis scanning, such as [1], [position()=1], [position() < 2], [position() > 3]
    # Returns operators and values such as [:==, 1], [:<, 2], [:>, 3]
    # Returns nil if the predicate is not a simple position-based predicate
    def position_operation(predicate_expr)
      return [:==, predicate_expr[1]] if predicate_expr[0] == :literal && predicate_expr[1].is_a?(Integer)

      op, left, right = predicate_expr
      return unless op == :eq || op == :lt || op == :lteq || op == :gt || op == :gteq
      return unless [left, right].include?([:function, 'position', []])

      literal = [left, right].find {|part| part[0] == :literal && part[1].is_a?(Integer) }
      return unless literal

      value = literal[1]
      case op
      when :eq
        [:==, value]
      when :lt
        literal == right ? [:<, value] : [:>, value]
      when :lteq
        literal == right ? [:<, value + 1] : [:>, value - 1]
      when :gt
        literal == right ? [:>, value]: [:<, value]
      when :gteq
        literal == right ? [:>, value - 1] : [:<, value + 1]
      end
    end

    # Pseudo scanner for axis scanning step that nodesets are already collected
    def iterate_nodesets(nodesets, tester, selector)
      non_optimized_nodesets_select(nodesets, tester, selector)
    end

    # Scanner for ancestor-or-self axis
    def ancestor_or_self(nodeset, tester, selector)
      ancestor(nodeset, tester, selector, include_self: true)
    end

    # Scanner for preceding-sibling axis
    def preceding_sibling(nodeset, tester, selector)
      preceding_following_sibling(nodeset, tester, selector, reverse: true)
    end

    # Scanner for following-sibling axis
    def following_sibling(nodeset, tester, selector)
      preceding_following_sibling(nodeset, tester, selector, reverse: false)
    end

    def preceding_following_sibling(nodeset, tester, selector, reverse:)
      nodeset = nodeset.select {|node| node.respond_to?(:parent) && node.parent }
      case selector
      when :uniq
        nodeset.group_by(&:parent).flat_map do |parent, sibling_nodes|
          sets = Set.new.compare_by_identity
          sibling_nodes.each {|sibling| sets << sibling }
          children = parent.children
          children = children.reverse if reverse
          children.drop_while {|child| !sets.include?(child) }.drop(1)
        end.select(&tester)
      when :nodesets
        nodesets = nodeset.map do |node|
          parent = node.parent
          index = parent.children.index(node)
          reverse ? parent.children[0...index].reverse : parent.children[index + 1..-1]
        end
        non_optimized_nodesets_select(nodesets, tester, selector)
      else
        operator, value = selector
        nodeset.group_by(&:parent).flat_map do |parent, sibling_nodes|
          anchors = Set.new.compare_by_identity
          sibling_nodes.each {|sibling| anchors << sibling }
          children = parent.children
          children = children.reverse if reverse
          followings = children.drop_while {|child| !anchors.include?(child) }.drop(1)
          anchor_indexes = Set[0]
          last_anchor = 0
          index = 0
          matched = []
          followings.each do |node|
            if tester.call(node)
              case operator
              when :==
                # anchor_indexes only contain values smaller or equal to `index`,
                # so value <= 0 case doesn't accidentally match any node.
                matched << node if anchor_indexes.include?(index - value + 1)
              when :<
                # Position from the last anchor will be the minimum possible position for the node
                matched << node if index - last_anchor + 1 < value
              when :>
                # Position from the first anchor(==0) will be the maximum possible position for the node
                matched << node if index + 1 > value
              end
              index += 1
            end
            if anchors.include?(node)
              anchor_indexes << index
              last_anchor = index
            end
          end
          matched
        end
      end
    end

    # Scanner for ancestor axis
    def ancestor(nodeset, tester, selector, include_self: false)
      nodeset = nodeset.select {|node| node.respond_to?(:parent) && node.parent }
      case selector
      when :uniq
        ancestors = Set.new.compare_by_identity
        nodeset.each do |node|
          ancestors << node if include_self
          parent = node.parent
          while parent
            break if ancestors.include?(parent)
            ancestors << parent
            parent = parent.parent
          end
        end
        ancestors.select(&tester)
      else
        # Slow pass
        nodesets = nodeset.map do |node|
          ancestors = []
          ancestors << node if include_self
          parent = node.parent
          while parent
            ancestors << parent
            parent = parent.parent
          end
          ancestors
        end
        non_optimized_nodesets_select(nodesets, tester, selector)
      end
    end

    # Scanner fallback step for axis that is not optimized for position-based predicates.
    def non_optimized_nodesets_select(nodesets, tester, selector)
      nodesets = nodesets.map do |nodeset|
        nodeset.select(&tester)
      end.reject(&:empty?)
      case selector
      when :nodesets
        nodesets
      when :uniq
        seen = Set.new.compare_by_identity
        nodesets.flatten.each {|node| seen << node }
        seen.to_a
      else
        operator, value = selector
        nodes =
          case operator
          when :==
            nodesets.map {|nodeset| nodeset[value - 1] if value >= 1 }.compact
          when :<
            nodesets.flat_map {|nodeset| nodeset[0...value - 1] if value >= 1 }.compact
          when :>
            nodesets.flat_map {|nodeset| value <= 0 ? nodeset : nodeset.drop(value) }
          end
        seen = Set.new.compare_by_identity
        nodes.each {|node| seen << node }
        seen.to_a
      end
    end

    # Split predicates into several groups based on their dependency on the position of nodes
    # If there are no position-based predicates,
    # return [position_independent_predicates, nil, [], nil]
    # If there are only one simple position-based predicate,
    # return [position_independent_predicates, position_operator, post_position_independent_predicates, nil]
    # If there are multiple position-based predicates or complex position-based predicates,
    # return [position_independent_predicates, nil, nil, complex_predicates]
    def split_positional_predicates(predicates)
      pre_independent = predicates.take_while {|predicate| !position_dependent?(predicate) }
      predicates = predicates.drop(pre_independent.size)
      return [pre_independent, nil, [], nil] if predicates.empty?

      op = position_operation(predicates.first)
      if op && predicates[1..-1].all? {|predicate| !position_dependent?(predicate) }
        [pre_independent, op, predicates[1..-1], nil]
      else
        [pre_independent, nil, nil, predicates]
      end
    end

    # Performs an axis scanning step.
    # The caller provides a scanner method and its argument, which determines the axis to scan and the nodes to scan from:
    #   step(path_stack) { [scanner_method, scanner_argument] }
    # Scanner methods are called with `(scanner_argument, tester_block, selector)`
    # selector is a flag for the scanner to determine how to return the scan result.
    # It can be: `:uniq`, `:nodesets` or `[position_comparator, value]`.
    # `:uniq` means the scanner should return unique nodes. Predicates are position-independent.
    # `:nodesets` means the scanner should return nodesets. Predicates are complex position queries that can't be optimized in axis scanning.
    # `[position_comparator, value]` means the scanner should return nodes matching the position comparator and value.
    # Each scanner method can implement optimized scanning strategy for each selector.

    def step(path_stack, any_type: :element)
      scanner, scanner_argument = yield
      begin
        enter(:step, path_stack, scanner, scanner_argument) if @debug
        tester = node_test(path_stack, any_type: any_type)
        predicates = []
        while path_stack.first == :predicate
          path_stack.shift
          predicates << path_stack.shift
        end
        pre_predicates, position_operator, post_predicates, complex_predicates = split_positional_predicates(predicates)

        if pre_predicates.any?
          original_tester = tester
          tester = -> (node) do
            original_tester.call(node) &&
            pre_predicates.all? do |predicate_expr|
              evaluate_predicate(predicate_expr.dclone, [[node]]).flatten.size == 1
            end
          end
        end
        if complex_predicates
          nodesets = send(scanner, scanner_argument, tester, :nodesets)
        elsif position_operator
          nodeset = send(scanner, scanner_argument, tester, position_operator)
          nodesets = [nodeset]
        else
          nodeset = send(scanner, scanner_argument, tester, :uniq)
          nodesets = [nodeset]
        end

        (complex_predicates || post_predicates).each do |predicate_expr|
          nodesets = evaluate_predicate(predicate_expr.dclone, nodesets)
        end
        nodes = Set.new.compare_by_identity
        nodesets.each do |nodeset|
          nodeset.each do |node|
            nodes << node
          end
        end
        new_nodeset = sort(nodes.to_a)
      ensure
        leave(:step, path_stack, new_nodeset) if @debug
      end
    end

    def node_test(path_stack, any_type: :element)
      enter(:node_test, path_stack) if @debug
      operator = path_stack.shift
      case operator
      when :qname
        prefix = path_stack.shift
        name = path_stack.shift
        ->(node) do
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
      when :namespace
        prefix = path_stack.shift
        ->(node) do
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
      when :any
        ->(node) do
          node.node_type == any_type
        end
      when :comment
        ->(node) do
          node.node_type == :comment
        end
      when :text
        ->(node) do
          node.node_type == :text
        end
      when :processing_instruction
        target = path_stack.shift
        ->(node) do
          (node.node_type == :processing_instruction) and
            (target.empty? or (node.target == target))
        end
      when :node
        ->(_node) do
          true
        end
      else
        message = "[BUG] Unexpected node test: " +
          "<#{operator.inspect}>: <#{path_stack.inspect}>"
        raise message
      end
    ensure
      leave(:node_test, path_stack) if @debug
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
      return array_of_nodes if array_of_nodes.size <= 1

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

    # Scanner for descendant-or-self axis
    def descendant_or_self(nodeset, tester, selector)
      descendant(nodeset, tester, selector, include_self: true)
    end

    # Scanner for descendant axis
    def descendant(nodeset, tester, selector, include_self: false)
      nodeset = nodeset.select {|node| node.respond_to?(:children) }
      case selector
      when :uniq
        seen = Set.new.compare_by_identity
        recursive = ->(node) do
          node_type = node.node_type
          return if seen.include?(node)
          seen << node if node_type != :xmldecl
          return unless node_type == :element || node_type == :document
          node.children.each do |child|
            recursive.call(child)
          end
        end
        nodeset.each do |node|
          if include_self
            recursive.call(node)
          else
            node.children.each(&recursive)
          end
        end
        seen.select(&tester)
      else
        nodesets = nodeset.map do |node|
          new_nodeset = []
          new_nodes = {}
          descendant_recursive(node, new_nodeset, new_nodes, include_self)
          new_nodeset
        end
        non_optimized_nodesets_select(nodesets, tester, selector)
      end
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

    # Scanner for preceding axis
    def preceding(nodeset, tester, selector)
      nodesets = nodeset.select {|node| node.respond_to?(:parent) }.map {|node| preceding_nodes(node) }
      non_optimized_nodesets_select(nodesets, tester, selector)
    end

    # Builds a nodeset of all of the preceding nodes of the supplied node,
    # in reverse document order
    # preceding:: includes every element in the document that precedes this node,
    # except for ancestors
    def preceding_nodes(node)
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

    # Scanner for following axis
    def following(nodeset, tester, selector)
      nodesets = nodeset.select {|node| node.respond_to?(:parent) }.map do |node|
        following_nodes(node)
      end
      non_optimized_nodesets_select(nodesets, tester, selector)
    end

    def following_nodes(node)
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
        @functions.boolean( b )
      when /^\d+(\.\d+)?$/, Numeric
        @functions.number( b )
      else
        @functions.string( b )
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
          node_string1 = @functions.string(node1)
          node_string2 = @functions.string(node2)
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
            compare(@functions.boolean(node), op, b)
          end
        when Numeric
          a.any? do |node|
            compare(@functions.number(node), op, b)
          end
        when /\A\d+(\.\d+)?\z/
          b = @functions.number(b)
          a.any? do |node|
            compare(@functions.number(node), op, b)
          end
        else
          b = @functions.string(b)
          a.any? do |node|
            compare(@functions.string(node), op, b)
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
          a = @functions.boolean(a) unless a_type == :boolean
          b = @functions.boolean(b) unless b_type == :boolean
        elsif a_type == :number or b_type == :number
          a = @functions.number(a) unless a_type == :number
          b = @functions.number(b) unless b_type == :number
        else
          a = @functions.string(a) unless a_type == :string
          b = @functions.string(b) unless b_type == :string
        end
      when :lt, :lteq, :gt, :gteq
        a = @functions.number(a) unless a_type == :number
        b = @functions.number(b) unless b_type == :number
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
