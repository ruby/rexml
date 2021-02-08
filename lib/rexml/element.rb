# frozen_string_literal: false
require_relative "parent"
require_relative "namespace"
require_relative "attribute"
require_relative "cdata"
require_relative "xpath"
require_relative "parseexception"

module REXML
  # An implementation note about namespaces:
  # As we parse, when we find namespaces we put them in a hash and assign
  # them a unique ID.  We then convert the namespace prefix for the node
  # to the unique ID.  This makes namespace lookup much faster for the
  # cost of extra memory use.  We save the namespace prefix for the
  # context node and convert it back when we write it.
  @@namespaces = {}

  # Represents a tagged XML element.  Elements are characterized by
  # having children, attributes, and names, and can themselves be
  # children.
  class Element < Parent
    include Namespace

    UNDEFINED = "UNDEFINED";            # The default name

    # Mechanisms for accessing attributes and child elements of this
    # element.
    attr_reader :attributes, :elements
    # The context holds information about the processing environment, such as
    # whitespace handling.
    attr_accessor :context

    # :call-seq:
    #   Element.new(name = 'UNDEFINED', parent = nil, context = nil) -> new_element
    #   Element.new(element, parent = nil, context = nil) -> new_element
    #
    # Returns a new \REXML::Element object.
    #
    # When no arguments are given,
    # returns an element with name <tt>'UNDEFINED'</tt>:
    #
    #   e = REXML::Element.new # => <UNDEFINED/>
    #   e.class                # => REXML::Element
    #   e.name                 # => "UNDEFINED"
    #
    # When only argument +name+ is given,
    # returns an element of the given name:
    #
    #   REXML::Element.new('foo') # => <foo/>
    #
    # When only argument +element+ is given, it must be an \REXML::Element object;
    # returns a shallow copy of the given element:
    #
    #   e0 = REXML::Element.new('foo')
    #   e1 = REXML::Element.new(e0) # => <foo/>
    #
    # When argument +parent+ is also given, it must be an REXML::Parent object:
    #
    #   e = REXML::Element.new('foo', REXML::Parent.new)
    #   e.parent # => #<REXML::Parent @parent=nil, @children=[<foo/>]>
    #
    # When argument +context+ is also given, it must be a hash
    # representing the context for the element;
    # see {Element Context}[../doc/rexml/context_rdoc.html]:
    #
    #   e = REXML::Element.new('foo', nil, {raw: :all})
    #   e.context # => {:raw=>:all}
    #
    def initialize( arg = UNDEFINED, parent=nil, context=nil )
      super(parent)

      @elements = Elements.new(self)
      @attributes = Attributes.new(self)
      @context = context

      if arg.kind_of? String
        self.name = arg
      elsif arg.kind_of? Element
        self.name = arg.expanded_name
        arg.attributes.each_attribute{ |attribute|
          @attributes << Attribute.new( attribute )
        }
        @context = arg.context
      end
    end

    # :call-seq:
    #   inspect -> string
    #
    # Returns a string representation of the element.
    #
    # For an element with no attributes and no children, shows the element name:
    #
    #   REXML::Element.new.inspect # => "<UNDEFINED/>"
    #
    # Shows attributes, if any:
    #
    #   e = REXML::Element.new('foo')
    #   e.add_attributes({'bar' => 0, 'baz' => 1})
    #   e.inspect # => "<foo bar='0' baz='1'/>"
    #
    # Shows an ellipsis (<tt>...</tt>), if there are child elements:
    #
    #   e.add_element(REXML::Element.new('bar'))
    #   e.add_element(REXML::Element.new('baz'))
    #   e.inspect # => "<foo bar='0' baz='1'> ... </>"
    #
    def inspect
      rv = "<#@expanded_name"

      @attributes.each_attribute do |attr|
        rv << " "
        attr.write( rv, 0 )
      end

      if children.size > 0
        rv << "> ... </>"
      else
        rv << "/>"
      end
    end

    # :call-seq:
    #   clone -> new_element
    #
    # Returns a shallow copy of the element, containing the name and attributes,
    # but not the parent or children:
    #
    #   e = REXML::Element.new('foo')
    #   e.add_attributes({'bar' => 0, 'baz' => 1})
    #   e.clone # => <foo bar='0' baz='1'/>
    #
    def clone
      self.class.new self
    end

    # :call-seq:
    #   root_node -> document or element
    #
    # Returns the most distant ancestor of +self+.
    #
    # When the element is part of a document,
    # returns the root node of the document.
    # Note that the root node is different from the document element;
    # in this example +a+ is document element and the root node is its parent:
    #
    #   d = REXML::Document.new('<a><b><c/></b></a>')
    #   top_element = d.first      # => <a> ... </>
    #   child = top_element.first  # => <b> ... </>
    #   d.root_node == d           # => true
    #   top_element.root_node == d # => true
    #   child.root_node == d       # => true
    #
    # When the element is not part of a document, but does have ancestor elements,
    # returns the most distant ancestor element:
    #
    #   e0 = REXML::Element.new('foo')
    #   e1 = REXML::Element.new('bar')
    #   e1.parent = e0
    #   e2 = REXML::Element.new('baz')
    #   e2.parent = e1
    #   e2.root_node == e0 # => true
    #
    # When the element has no ancestor elements,
    # returns +self+:
    #
    #   e = REXML::Element.new('foo')
    #   e.root_node == e # => true
    #
    # Related: #root, #document.
    #
    def root_node
      parent.nil? ? self : parent.root_node
    end

    # :call-seq:
    #   root -> element
    #
    # Returns the most distant _element_ (not document) ancestor of the element:
    #
    #   d = REXML::Document.new('<a><b><c/></b></a>')
    #   top_element = d.first
    #   child = top_element.first
    #   top_element.root == top_element # => true
    #   child.root == top_element       # => true
    #
    # For a document, returns the topmost element:
    #
    #   d.root == top_element # => true
    #
    # Related: #root_node, #document.
    #
    def root
      return elements[1] if self.kind_of? Document
      return self if parent.kind_of? Document or parent.nil?
      return parent.root
    end

    # :call-seq:
    #   document -> document or nil
    #
    # If the element is part of a document, returns that document:
    #
    #   d = REXML::Document.new('<a><b><c/></b></a>')
    #   top_element = d.first
    #   child = top_element.first
    #   top_element.document == d # => true
    #   child.document == d       # => true
    #
    # If the element is not part of a document, returns +nil+:
    #
    #   REXML::Element.new.document # => nil
    #
    # For a document, returns +self+:
    #
    #   d.document == d           # => true
    #
    # Related: #root, #root_node.
    #
    def document
      rt = root
      rt.parent if rt
    end

    # :call-seq:
    #   whitespace
    #
    # Returns +true+ if whitespace is respected for this element,
    # +false+ otherwise.
    #
    # See {Element Context}[../doc/rexml/context_rdoc.html].
    #
    # The evaluation is tested against the element's +expanded_name+,
    # and so is namespace-sensitive.
    def whitespace
      @whitespace = nil
      if @context
        if @context[:respect_whitespace]
          @whitespace = (@context[:respect_whitespace] == :all or
                         @context[:respect_whitespace].include? expanded_name)
        end
        @whitespace = false if (@context[:compress_whitespace] and
                                (@context[:compress_whitespace] == :all or
                                 @context[:compress_whitespace].include? expanded_name)
                               )
      end
      @whitespace = true unless @whitespace == false
      @whitespace
    end

    # :call-seq:
    #   ignore_whitespace_nodes
    #
    # Returns +true+ if whitespace nodes are ignored for the element.
    #
    # See {Element Context}[../doc/rexml/context_rdoc.html].
    #
    def ignore_whitespace_nodes
      @ignore_whitespace_nodes = false
      if @context
        if @context[:ignore_whitespace_nodes]
          @ignore_whitespace_nodes =
            (@context[:ignore_whitespace_nodes] == :all or
             @context[:ignore_whitespace_nodes].include? expanded_name)
        end
      end
    end

    # :call-seq:
    #   raw
    #
    # Returns +true+ if raw mode is set for the element.
    #
    # See {Element Context}[../doc/rexml/context_rdoc.html].
    #
    # The evaluation is tested against +expanded_name+, and so is namespace
    # sensitive.
    def raw
      @raw = (@context and @context[:raw] and
              (@context[:raw] == :all or
               @context[:raw].include? expanded_name))
      @raw
    end

    #once :whitespace, :raw, :ignore_whitespace_nodes

    #################################################
    # Namespaces                                    #
    #################################################

    # :call-seq:
    #   prefixes -> array_of_namespace_prefixes
    #
    # Returns an array of the string prefixes (names) of all defined namespaces
    # in the element and its ancestors:
    #
    #   xml_string = <<-EOT
    #     <root>
    #        <a xmlns:x='1' xmlns:y='2'>
    #          <b/>
    #          <c xmlns:z='3'/>
    #        </a>
    #     </root>
    #   EOT
    #   d = REXML::Document.new(xml_string, {compress_whitespace: :all})
    #   d.elements['//a'].prefixes # => ["x", "y"]
    #   d.elements['//b'].prefixes # => ["x", "y"]
    #   d.elements['//c'].prefixes # => ["x", "y", "z"]
    #
    def prefixes
      prefixes = []
      prefixes = parent.prefixes if parent
      prefixes |= attributes.prefixes
      return prefixes
    end

    # :call-seq:
    #    namespaces -> array_of_namespace_names
    #
    # Returns a hash of all defined namespaces
    # in the element and its ancestors:
    #
    #   xml_string = <<-EOT
    #     <root>
    #        <a xmlns:x='1' xmlns:y='2'>
    #          <b/>
    #          <c xmlns:z='3'/>
    #        </a>
    #     </root>
    #   EOT
    #   d = REXML::Document.new(xml_string)
    #   d.elements['//a'].namespaces # => {"x"=>"1", "y"=>"2"}
    #   d.elements['//b'].namespaces # => {"x"=>"1", "y"=>"2"}
    #   d.elements['//c'].namespaces # => {"x"=>"1", "y"=>"2", "z"=>"3"}
    #
    def namespaces
      namespaces = {}
      namespaces = parent.namespaces if parent
      namespaces = namespaces.merge( attributes.namespaces )
      return namespaces
    end

    # :call-seq:
    #   namespace(prefix = nil) -> string_uri or nil
    #
    # Returns the string namespace URI for the element,
    # possibly deriving from one of its ancestors.
    #
    #   xml_string = <<-EOT
    #     <root>
    #        <a xmlns='1' xmlns:y='2'>
    #          <b/>
    #          <c xmlns:z='3'/>
    #        </a>
    #     </root>
    #   EOT
    #   d = REXML::Document.new(xml_string)
    #   b = d.elements['//b']
    #   b.namespace      # => "1"
    #   b.namespace('y') # => "2"
    #   b.namespace('nosuch') # => nil
    #
    def namespace(prefix=nil)
      if prefix.nil?
        prefix = prefix()
      end
      if prefix == ''
        prefix = "xmlns"
      else
        prefix = "xmlns:#{prefix}" unless prefix[0,5] == 'xmlns'
      end
      ns = attributes[ prefix ]
      ns = parent.namespace(prefix) if ns.nil? and parent
      ns = '' if ns.nil? and prefix == 'xmlns'
      return ns
    end

    # :call-seq:
    #   add_namespace(prefix, uri = nil) -> self
    #
    # Adds a namespace to the element; returns +self+.
    #
    # With the single argument +prefix+,
    # adds a namespace using the given +prefix+ and the namespace URI:
    #
    #   e = REXML::Element.new('foo')
    #   e.add_namespace('bar')
    #   e.namespaces # => {"xmlns"=>"bar"}
    #
    # With both arguments +prefix+ and +uri+ given,
    # adds a namespace using both arguments:
    #
    #   e.add_namespace('baz', 'bat')
    #   e.namespaces # => {"xmlns"=>"bar", "baz"=>"bat"}
    #
    def add_namespace( prefix, uri=nil )
      unless uri
        @attributes["xmlns"] = prefix
      else
        prefix = "xmlns:#{prefix}" unless prefix =~ /^xmlns:/
        @attributes[ prefix ] = uri
      end
      self
    end

    # :call-seq:
    #   delete_namespace(namespace = 'xmlns') -> self
    #
    # Removes a namespace from the element.
    #
    # With no argument, removes the default namespace:
    #
    #   d = REXML::Document.new "<a xmlns:foo='bar' xmlns='twiddle'/>"
    #   d.to_s # => "<a xmlns:foo='bar' xmlns='twiddle'/>"
    #   d.root.delete_namespace # => <a xmlns:foo='bar'/>
    #   d.to_s # => "<a xmlns:foo='bar'/>"
    #
    # With argument +namespace+, removes the specified namespace:
    #
    #   d.root.delete_namespace('foo')
    #   d.to_s # => "<a/>"
    #
    # Does nothing if no such namespace is found:
    #
    #   d.root.delete_namespace('nosuch')
    #   d.to_s # => "<a/>"
    #
    def delete_namespace namespace="xmlns"
      namespace = "xmlns:#{namespace}" unless namespace == 'xmlns'
      attribute = attributes.get_attribute(namespace)
      attribute.remove unless attribute.nil?
      self
    end

    #################################################
    # Elements                                      #
    #################################################

    # Adds a child to this element, optionally setting attributes in
    # the element.
    # element::
    #   optional.  If Element, the element is added.
    #   Otherwise, a new Element is constructed with the argument (see
    #   Element.initialize).
    # attrs::
    #   If supplied, must be a Hash containing String name,value
    #   pairs, which will be used to set the attributes of the new Element.
    # Returns:: the Element that was added
    #  el = doc.add_element 'my-tag'
    #  el = doc.add_element 'my-tag', {'attr1'=>'val1', 'attr2'=>'val2'}
    #  el = Element.new 'my-tag'
    #  doc.add_element el
    def add_element element, attrs=nil
      raise "First argument must be either an element name, or an Element object" if element.nil?
      el = @elements.add(element)
      attrs.each do |key, value|
        el.attributes[key]=value
      end       if attrs.kind_of? Hash
      el
    end

    # Deletes a child element.
    # element::
    #   Must be an +Element+, +String+, or +Integer+.  If Element,
    #   the element is removed.  If String, the element is found (via XPath)
    #   and removed.  <em>This means that any parent can remove any
    #   descendant.<em>  If Integer, the Element indexed by that number will be
    #   removed.
    # Returns:: the element that was removed.
    #  doc.delete_element "/a/b/c[@id='4']"
    #  doc.delete_element doc.elements["//k"]
    #  doc.delete_element 1
    def delete_element element
      @elements.delete element
    end

    # Evaluates to +true+ if this element has at least one child Element
    #  doc = Document.new "<a><b/><c>Text</c></a>"
    #  doc.root.has_elements               # -> true
    #  doc.elements["/a/b"].has_elements   # -> false
    #  doc.elements["/a/c"].has_elements   # -> false
    def has_elements?
      !@elements.empty?
    end

    # Iterates through the child elements, yielding for each Element that
    # has a particular attribute set.
    # key::
    #   the name of the attribute to search for
    # value::
    #   the value of the attribute
    # max::
    #   (optional) causes this method to return after yielding
    #   for this number of matching children
    # name::
    #   (optional) if supplied, this is an XPath that filters
    #   the children to check.
    #
    #  doc = Document.new "<a><b @id='1'/><c @id='2'/><d @id='1'/><e/></a>"
    #  # Yields b, c, d
    #  doc.root.each_element_with_attribute( 'id' ) {|e| p e}
    #  # Yields b, d
    #  doc.root.each_element_with_attribute( 'id', '1' ) {|e| p e}
    #  # Yields b
    #  doc.root.each_element_with_attribute( 'id', '1', 1 ) {|e| p e}
    #  # Yields d
    #  doc.root.each_element_with_attribute( 'id', '1', 0, 'd' ) {|e| p e}
    def each_element_with_attribute( key, value=nil, max=0, name=nil, &block ) # :yields: Element
      each_with_something( proc {|child|
        if value.nil?
          child.attributes[key] != nil
        else
          child.attributes[key]==value
        end
      }, max, name, &block )
    end

    # Iterates through the children, yielding for each Element that
    # has a particular text set.
    # text::
    #   the text to search for.  If nil, or not supplied, will iterate
    #   over all +Element+ children that contain at least one +Text+ node.
    # max::
    #   (optional) causes this method to return after yielding
    #   for this number of matching children
    # name::
    #   (optional) if supplied, this is an XPath that filters
    #   the children to check.
    #
    #  doc = Document.new '<a><b>b</b><c>b</c><d>d</d><e/></a>'
    #  # Yields b, c, d
    #  doc.each_element_with_text {|e|p e}
    #  # Yields b, c
    #  doc.each_element_with_text('b'){|e|p e}
    #  # Yields b
    #  doc.each_element_with_text('b', 1){|e|p e}
    #  # Yields d
    #  doc.each_element_with_text(nil, 0, 'd'){|e|p e}
    def each_element_with_text( text=nil, max=0, name=nil, &block ) # :yields: Element
      each_with_something( proc {|child|
        if text.nil?
          child.has_text?
        else
          child.text == text
        end
      }, max, name, &block )
    end

    # Synonym for Element.elements.each
    def each_element( xpath=nil, &block ) # :yields: Element
      @elements.each( xpath, &block )
    end

    # Synonym for Element.to_a
    # This is a little slower than calling elements.each directly.
    # xpath:: any XPath by which to search for elements in the tree
    # Returns:: an array of Elements that match the supplied path
    def get_elements( xpath )
      @elements.to_a( xpath )
    end

    # Returns the next sibling that is an element, or nil if there is
    # no Element sibling after this one
    #  doc = Document.new '<a><b/>text<c/></a>'
    #  doc.root.elements['b'].next_element          #-> <c/>
    #  doc.root.elements['c'].next_element          #-> nil
    def next_element
      element = next_sibling
      element = element.next_sibling until element.nil? or element.kind_of? Element
      return element
    end

    # Returns the previous sibling that is an element, or nil if there is
    # no Element sibling prior to this one
    #  doc = Document.new '<a><b/>text<c/></a>'
    #  doc.root.elements['c'].previous_element          #-> <b/>
    #  doc.root.elements['b'].previous_element          #-> nil
    def previous_element
      element = previous_sibling
      element = element.previous_sibling until element.nil? or element.kind_of? Element
      return element
    end


    #################################################
    # Text                                          #
    #################################################

    # Evaluates to +true+ if this element has at least one Text child
    def has_text?
      not text().nil?
    end

    # A convenience method which returns the String value of the _first_
    # child text element, if one exists, and +nil+ otherwise.
    #
    # <em>Note that an element may have multiple Text elements, perhaps
    # separated by other children</em>.  Be aware that this method only returns
    # the first Text node.
    #
    # This method returns the +value+ of the first text child node, which
    # ignores the +raw+ setting, so always returns normalized text. See
    # the Text::value documentation.
    #
    #  doc = Document.new "<p>some text <b>this is bold!</b> more text</p>"
    #  # The element 'p' has two text elements, "some text " and " more text".
    #  doc.root.text              #-> "some text "
    def text( path = nil )
      rv = get_text(path)
      return rv.value unless rv.nil?
      nil
    end

    # Returns the first child Text node, if any, or +nil+ otherwise.
    # This method returns the actual +Text+ node, rather than the String content.
    #  doc = Document.new "<p>some text <b>this is bold!</b> more text</p>"
    #  # The element 'p' has two text elements, "some text " and " more text".
    #  doc.root.get_text.value            #-> "some text "
    def get_text path = nil
      rv = nil
      if path
        element = @elements[ path ]
        rv = element.get_text unless element.nil?
      else
        rv = @children.find { |node| node.kind_of? Text }
      end
      return rv
    end

    # Sets the first Text child of this object.  See text() for a
    # discussion about Text children.
    #
    # If a Text child already exists, the child is replaced by this
    # content.  This means that Text content can be deleted by calling
    # this method with a nil argument.  In this case, the next Text
    # child becomes the first Text child.  In no case is the order of
    # any siblings disturbed.
    # text::
    #   If a String, a new Text child is created and added to
    #   this Element as the first Text child.  If Text, the text is set
    #   as the first Child element.  If nil, then any existing first Text
    #   child is removed.
    # Returns:: this Element.
    #  doc = Document.new '<a><b/></a>'
    #  doc.root.text = 'Sean'      #-> '<a><b/>Sean</a>'
    #  doc.root.text = 'Elliott'   #-> '<a><b/>Elliott</a>'
    #  doc.root.add_element 'c'    #-> '<a><b/>Elliott<c/></a>'
    #  doc.root.text = 'Russell'   #-> '<a><b/>Russell<c/></a>'
    #  doc.root.text = nil         #-> '<a><b/><c/></a>'
    def text=( text )
      if text.kind_of? String
        text = Text.new( text, whitespace(), nil, raw() )
      elsif !text.nil? and !text.kind_of? Text
        text = Text.new( text.to_s, whitespace(), nil, raw() )
      end
      old_text = get_text
      if text.nil?
        old_text.remove unless old_text.nil?
      else
        if old_text.nil?
          self << text
        else
          old_text.replace_with( text )
        end
      end
      return self
    end

    # A helper method to add a Text child.  Actual Text instances can
    # be added with regular Parent methods, such as add() and <<()
    # text::
    #   if a String, a new Text instance is created and added
    #   to the parent.  If Text, the object is added directly.
    # Returns:: this Element
    #  e = Element.new('a')          #-> <e/>
    #  e.add_text 'foo'              #-> <e>foo</e>
    #  e.add_text Text.new(' bar')    #-> <e>foo bar</e>
    # Note that at the end of this example, the branch has <b>3</b> nodes; the 'e'
    # element and <b>2</b> Text node children.
    def add_text( text )
      if text.kind_of? String
        if @children[-1].kind_of? Text
          @children[-1] << text
          return
        end
        text = Text.new( text, whitespace(), nil, raw() )
      end
      self << text unless text.nil?
      return self
    end

    def node_type
      :element
    end

    def xpath
      path_elements = []
      cur = self
      path_elements << __to_xpath_helper( self )
      while cur.parent
        cur = cur.parent
        path_elements << __to_xpath_helper( cur )
      end
      return path_elements.reverse.join( "/" )
    end

    #################################################
    # Attributes                                    #
    #################################################

    # Fetches an attribute value or a child.
    #
    # If String or Symbol is specified, it's treated as attribute
    # name. Attribute value as String or +nil+ is returned. This case
    # is shortcut of +attributes[name]+.
    #
    # If Integer is specified, it's treated as the index of
    # child. It returns Nth child.
    #
    #   doc = REXML::Document.new("<a attr='1'><b/><c/></a>")
    #   doc.root["attr"]             # => "1"
    #   doc.root.attributes["attr"]  # => "1"
    #   doc.root[1]                  # => <c/>
    def [](name_or_index)
      case name_or_index
      when String
        attributes[name_or_index]
      when Symbol
        attributes[name_or_index.to_s]
      else
        super
      end
    end

    def attribute( name, namespace=nil )
      prefix = nil
      if namespaces.respond_to? :key
        prefix = namespaces.key(namespace) if namespace
      else
        prefix = namespaces.index(namespace) if namespace
      end
      prefix = nil if prefix == 'xmlns'

      ret_val =
        attributes.get_attribute( "#{prefix ? prefix + ':' : ''}#{name}" )

      return ret_val unless ret_val.nil?
      return nil if prefix.nil?

      # now check that prefix'es namespace is not the same as the
      # default namespace
      return nil unless ( namespaces[ prefix ] == namespaces[ 'xmlns' ] )

      attributes.get_attribute( name )

    end

    # Evaluates to +true+ if this element has any attributes set, false
    # otherwise.
    def has_attributes?
      return !@attributes.empty?
    end

    # Adds an attribute to this element, overwriting any existing attribute
    # by the same name.
    # key::
    #   can be either an Attribute or a String.  If an Attribute,
    #   the attribute is added to the list of Element attributes.  If String,
    #   the argument is used as the name of the new attribute, and the value
    #   parameter must be supplied.
    # value::
    #   Required if +key+ is a String, and ignored if the first argument is
    #   an Attribute.  This is a String, and is used as the value
    #   of the new Attribute.  This should be the unnormalized value of the
    #   attribute (without entities).
    # Returns:: the Attribute added
    #  e = Element.new 'e'
    #  e.add_attribute( 'a', 'b' )               #-> <e a='b'/>
    #  e.add_attribute( 'x:a', 'c' )             #-> <e a='b' x:a='c'/>
    #  e.add_attribute Attribute.new('b', 'd')   #-> <e a='b' x:a='c' b='d'/>
    def add_attribute( key, value=nil )
      if key.kind_of? Attribute
        @attributes << key
      else
        @attributes[key] = value
      end
    end

    # Add multiple attributes to this element.
    # hash:: is either a hash, or array of arrays
    #  el.add_attributes( {"name1"=>"value1", "name2"=>"value2"} )
    #  el.add_attributes( [ ["name1","value1"], ["name2"=>"value2"] ] )
    def add_attributes hash
      if hash.kind_of? Hash
        hash.each_pair {|key, value| @attributes[key] = value }
      elsif hash.kind_of? Array
        hash.each { |value| @attributes[ value[0] ] = value[1] }
      end
    end

    # Removes an attribute
    # key::
    #   either an Attribute or a String.  In either case, the
    #   attribute is found by matching the attribute name to the argument,
    #   and then removed.  If no attribute is found, no action is taken.
    # Returns::
    #   the attribute removed, or nil if this Element did not contain
    #   a matching attribute
    #  e = Element.new('E')
    #  e.add_attribute( 'name', 'Sean' )             #-> <E name='Sean'/>
    #  r = e.add_attribute( 'sur:name', 'Russell' )  #-> <E name='Sean' sur:name='Russell'/>
    #  e.delete_attribute( 'name' )                  #-> <E sur:name='Russell'/>
    #  e.delete_attribute( r )                       #-> <E/>
    def delete_attribute(key)
      attr = @attributes.get_attribute(key)
      attr.remove unless attr.nil?
    end

    #################################################
    # Other Utilities                               #
    #################################################

    # Get an array of all CData children.
    # IMMUTABLE
    def cdatas
      find_all { |child| child.kind_of? CData }.freeze
    end

    # Get an array of all Comment children.
    # IMMUTABLE
    def comments
      find_all { |child| child.kind_of? Comment }.freeze
    end

    # Get an array of all Instruction children.
    # IMMUTABLE
    def instructions
      find_all { |child| child.kind_of? Instruction }.freeze
    end

    # Get an array of all Text children.
    # IMMUTABLE
    def texts
      find_all { |child| child.kind_of? Text }.freeze
    end

    # == DEPRECATED
    # See REXML::Formatters
    #
    # Writes out this element, and recursively, all children.
    # output::
    #     output an object which supports '<< string'; this is where the
    #   document will be written.
    # indent::
    #   An integer.  If -1, no indenting will be used; otherwise, the
    #   indentation will be this number of spaces, and children will be
    #   indented an additional amount.  Defaults to -1
    # transitive::
    #   If transitive is true and indent is >= 0, then the output will be
    #   pretty-printed in such a way that the added whitespace does not affect
    #   the parse tree of the document
    # ie_hack::
    #   This hack inserts a space before the /> on empty tags to address
    #   a limitation of Internet Explorer.  Defaults to false
    #
    #  out = ''
    #  doc.write( out )     #-> doc is written to the string 'out'
    #  doc.write( $stdout ) #-> doc written to the console
    def write(output=$stdout, indent=-1, transitive=false, ie_hack=false)
      Kernel.warn("#{self.class.name}.write is deprecated.  See REXML::Formatters", uplevel: 1)
      formatter = if indent > -1
          if transitive
            require_relative "formatters/transitive"
            REXML::Formatters::Transitive.new( indent, ie_hack )
          else
            REXML::Formatters::Pretty.new( indent, ie_hack )
          end
        else
          REXML::Formatters::Default.new( ie_hack )
        end
      formatter.write( self, output )
    end


    private
    def __to_xpath_helper node
      rv = node.expanded_name.clone
      if node.parent
        results = node.parent.find_all {|n|
          n.kind_of?(REXML::Element) and n.expanded_name == node.expanded_name
        }
        if results.length > 1
          idx = results.index( node )
          rv << "[#{idx+1}]"
        end
      end
      rv
    end

    # A private helper method
    def each_with_something( test, max=0, name=nil )
      num = 0
      @elements.each( name ){ |child|
        yield child if test.call(child) and num += 1
        return if max>0 and num == max
      }
    end
  end

  ########################################################################
  # ELEMENTS                                                             #
  ########################################################################

  # A class which provides filtering of children for Elements, and
  # XPath search support.  You are expected to only encounter this class as
  # the <tt>element.elements</tt> object.  Therefore, you are
  # _not_ expected to instantiate this yourself.
  #
  #   xml_string = <<-EOT
  #   <?xml version="1.0" encoding="UTF-8"?>
  #   <bookstore>
  #     <book category="cooking">
  #       <title lang="en">Everyday Italian</title>
  #       <author>Giada De Laurentiis</author>
  #       <year>2005</year>
  #       <price>30.00</price>
  #     </book>
  #     <book category="children">
  #       <title lang="en">Harry Potter</title>
  #       <author>J K. Rowling</author>
  #       <year>2005</year>
  #       <price>29.99</price>
  #     </book>
  #     <book category="web">
  #       <title lang="en">XQuery Kick Start</title>
  #       <author>James McGovern</author>
  #       <author>Per Bothner</author>
  #       <author>Kurt Cagle</author>
  #       <author>James Linn</author>
  #       <author>Vaidyanathan Nagarajan</author>
  #       <year>2003</year>
  #       <price>49.99</price>
  #     </book>
  #     <book category="web" cover="paperback">
  #       <title lang="en">Learning XML</title>
  #       <author>Erik T. Ray</author>
  #       <year>2003</year>
  #       <price>39.95</price>
  #     </book>
  #   </bookstore>
  #   EOT
  #   d = REXML::Document.new(xml_string)
  #   elements = d.root.elements
  #   elements # => #<REXML::Elements @element=<bookstore> ... </>>
  #
  class Elements
    include Enumerable
    # :call-seq:
    #   new(base_element) -> new_elements_object
    #
    # Returns a new \Elements object with the given +base_element+.
    # Does _not_ assign <tt>base_element.elements = self</tt>:
    #
    #   d = REXML::Document.new(xml_string)
    #   eles = REXML::Elements.new(d.root)
    #   eles # => #<REXML::Elements @element=<bookstore> ... </>>
    #   eles == d.root.elements # => false
    #
    # To retrieve the given +base_element+:
    #
    #   eles['.'] # => <bookstore> ... </>
    #
    def initialize parent
      @element = parent
    end

    # :call-seq:
    #   elements[index] -> element or nil
    #   elements[xpath] -> element or nil
    #   elements[n, name] -> element or nil
    #
    # Returns the first \Element object selected by the arguments,
    # if any found, or +nil+ if none found.
    #
    # Notes:
    # - The +index+ is 1-based, not 0-based, so that:
    #   - The first element has index <tt>1</tt>
    #   - The _nth_ element has index +n+.
    # - The selection ignores non-\Element nodes.
    #
    # When the single argument +index+ is given,
    # returns the element given by the index, if any; otherwise, +nil+:
    #
    #   d = REXML::Document.new(xml_string)
    #   eles = d.root.elements
    #   eles # => #<REXML::Elements @element=<bookstore> ... </>>
    #   eles[1] # => <book category='cooking'> ... </>
    #   eles.size # => 4
    #   eles[4] # => <book category='web' cover='paperback'> ... </>
    #   eles[5] # => nil
    #
    # The node at this index is not an \Element, and so is not returned:
    #
    #   eles = d.root.first.first # => <title lang='en'> ... </>
    #   eles.to_a # => ["Everyday Italian"]
    #   eles[1] # => nil
    #
    # When the single argument +xpath+ is given,
    # returns the first element found via that +xpath+, if any; otherwise, +nil+:
    #
    #   eles = d.root.elements # => #<REXML::Elements @element=<bookstore> ... </>>
    #   eles['/bookstore']                    # => <bookstore> ... </>
    #   eles['//book']                        # => <book category='cooking'> ... </>
    #   eles['//book [@category="children"]'] # => <book category='children'> ... </>
    #   eles['/nosuch']                       # => nil
    #   eles['//nosuch']                      # => nil
    #   eles['//book [@category="nosuch"]']   # => nil
    #   eles['.']                             # => <bookstore> ... </>
    #   eles['..'].class                      # => REXML::Document
    #
    # With arguments +n+ and +name+ given,
    # returns the _nth_ found element that has the given +name+,
    # or +nil+ if there is no such _nth_ element:
    #
    #   eles = d.root.elements # => #<REXML::Elements @element=<bookstore> ... </>>
    #   eles[1, 'book'] # => <book category='cooking'> ... </>
    #   eles[4, 'book'] # => <book category='web' cover='paperback'> ... </>
    #   eles[5, 'book'] # => nil
    #
    def []( index, name=nil)
      if index.kind_of? Integer
        raise "index (#{index}) must be >= 1" if index < 1
        name = literalize(name) if name
        num = 0
        @element.find { |child|
          child.kind_of? Element and
          (name.nil? ? true : child.has_name?( name )) and
          (num += 1) == index
        }
      else
        return XPath::first( @element, index )
        #{ |element|
        #       return element if element.kind_of? Element
        #}
        #return nil
      end
    end

    # :call-seq:
    #  elements[] = index, replacement_element -> replacement_element or nil
    #
    # Replaces or adds an element.
    #
    # When <tt>eles[index]</tt> exists, replaces it with +replacement_element+
    # and returns +replacement_element+:
    #
    #   d = REXML::Document.new(xml_string)
    #   eles = d.root.elements # => #<REXML::Elements @element=<bookstore> ... </>>
    #   eles[1] # => <book category='cooking'> ... </>
    #   eles[1] = REXML::Element.new('foo')
    #   eles[1] # => <foo/>
    #
    # Does nothing (or raises an exception)
    # if +replacement_element+ is not an \Element:
    #   eles[2] # => <book category='web' cover='paperback'> ... </>
    #   eles[2] = REXML::Text.new('bar')
    #   eles[2] # => <book category='web' cover='paperback'> ... </>
    #
    # When <tt>eles[index]</tt> does not exist,
    # adds +replacement_element+ to the element and returns
    #
    #   d = REXML::Document.new(xml_string)
    #   eles = d.root.elements # => #<REXML::Elements @element=<bookstore> ... </>>
    #   eles.size # => 4
    #   eles[50] = REXML::Element.new('foo') # => <foo/>
    #   eles.size # => 5
    #   eles[5] # => <foo/>
    #
    # Does nothing (or raises an exception)
    # if +replacement_element+ is not an \Element:
    #
    #   eles[50] = REXML::Text.new('bar') # => "bar"
    #   eles.size # => 5
    #
    def []=( index, element )
      previous = self[index]
      if previous.nil?
        @element.add element
      else
        previous.replace_with element
      end
      return previous
    end

    # :call-seq:
    #   empty? -> true or false
    #
    # Returns +true+ if there are no children, +false+ otherwise.
    #
    #   d = REXML::Document.new('')
    #   d.elements.empty? # => true
    #   d = REXML::Document.new(xml_string)
    #   d.elements.empty? # => false
    #
    def empty?
      @element.find{ |child| child.kind_of? Element}.nil?
    end

    # :call-seq:
    #   index(element)
    #
    # Returns the 1-based index of the given +element+, if found;
    # otherwise, returns -1:
    #
    #   d = REXML::Document.new(xml_string)
    #   elements = d.root.elements
    #   ele_1, ele_2, ele_3, ele_4 = *elements
    #   elements.index(ele_4) # => 4
    #   elements.delete(ele_3)
    #   elements.index(ele_4) # => 3
    #   elements.index(ele_3) # => -1
    #
    def index element
      rv = 0
      found = @element.find do |child|
        child.kind_of? Element and
        (rv += 1) and
        child == element
      end
      return rv if found == element
      return -1
    end

    # Deletes a child Element
    # element::
    #   Either an Element, which is removed directly; an
    #   xpath, where the first matching child is removed; or an Integer,
    #   where the n'th Element is removed.
    # Returns:: the removed child
    #  doc = Document.new '<a><b/><c/><c id="1"/></a>'
    #  b = doc.root.elements[1]
    #  doc.root.elements.delete b           #-> <a><c/><c id="1"/></a>
    #  doc.elements.delete("a/c[@id='1']")  #-> <a><c/></a>
    #  doc.root.elements.delete 1           #-> <a/>
    def delete element
      if element.kind_of? Element
        @element.delete element
      else
        el = self[element]
        el.remove if el
      end
    end

    # Removes multiple elements.  Filters for Element children, regardless of
    # XPath matching.
    # xpath:: all elements matching this String path are removed.
    # Returns:: an Array of Elements that have been removed
    #  doc = Document.new '<a><c/><c/><c/><c/></a>'
    #  deleted = doc.elements.delete_all 'a/c' #-> [<c/>, <c/>, <c/>, <c/>]
    def delete_all( xpath )
      rv = []
      XPath::each( @element, xpath) {|element|
        rv << element if element.kind_of? Element
      }
      rv.each do |element|
        @element.delete element
        element.remove
      end
      return rv
    end

    # Adds an element
    # element::
    #   if supplied, is either an Element, String, or
    #   Source (see Element.initialize).  If not supplied or nil, a
    #   new, default Element will be constructed
    # Returns:: the added Element
    #  a = Element.new('a')
    #  a.elements.add(Element.new('b'))  #-> <a><b/></a>
    #  a.elements.add('c')               #-> <a><b/><c/></a>
    def add element=nil
      if element.nil?
        Element.new("", self, @element.context)
      elsif not element.kind_of?(Element)
        Element.new(element, self, @element.context)
      else
        @element << element
        element.context = @element.context
        element
      end
    end

    alias :<< :add

    # Iterates through all of the child Elements, optionally filtering
    # them by a given XPath
    # xpath::
    #   optional.  If supplied, this is a String XPath, and is used to
    #   filter the children, so that only matching children are yielded.  Note
    #   that XPaths are automatically filtered for Elements, so that
    #   non-Element children will not be yielded
    #  doc = Document.new '<a><b/><c/><d/>sean<b/><c/><d/></a>'
    #  doc.root.elements.each {|e|p e}       #-> Yields b, c, d, b, c, d elements
    #  doc.root.elements.each('b') {|e|p e}  #-> Yields b, b elements
    #  doc.root.elements.each('child::node()')  {|e|p e}
    #  #-> Yields <b/>, <c/>, <d/>, <b/>, <c/>, <d/>
    #  XPath.each(doc.root, 'child::node()', &block)
    #  #-> Yields <b/>, <c/>, <d/>, sean, <b/>, <c/>, <d/>
    def each( xpath=nil )
      XPath::each( @element, xpath ) {|e| yield e if e.kind_of? Element }
    end

    def collect( xpath=nil )
      collection = []
      XPath::each( @element, xpath ) {|e|
        collection << yield(e)  if e.kind_of?(Element)
      }
      collection
    end

    def inject( xpath=nil, initial=nil )
      first = true
      XPath::each( @element, xpath ) {|e|
        if (e.kind_of? Element)
          if (first and initial == nil)
            initial = e
            first = false
          else
            initial = yield( initial, e ) if e.kind_of? Element
          end
        end
      }
      initial
    end

    # Returns the number of +Element+ children of the parent object.
    #  doc = Document.new '<a>sean<b/>elliott<b/>russell<b/></a>'
    #  doc.root.size            #-> 6, 3 element and 3 text nodes
    #  doc.root.elements.size   #-> 3
    def size
      count = 0
      @element.each {|child| count+=1 if child.kind_of? Element }
      count
    end

    # Returns an Array of Element children.  An XPath may be supplied to
    # filter the children.  Only Element children are returned, even if the
    # supplied XPath matches non-Element children.
    #  doc = Document.new '<a>sean<b/>elliott<c/></a>'
    #  doc.root.elements.to_a                  #-> [ <b/>, <c/> ]
    #  doc.root.elements.to_a("child::node()") #-> [ <b/>, <c/> ]
    #  XPath.match(doc.root, "child::node()")  #-> [ sean, <b/>, elliott, <c/> ]
    def to_a( xpath=nil )
      rv = XPath.match( @element, xpath )
      return rv.find_all{|e| e.kind_of? Element} if xpath
      rv
    end

    private
    # Private helper class.  Removes quotes from quoted strings
    def literalize name
      name = name[1..-2] if name[0] == ?' or name[0] == ?"               #'
      name
    end
  end

  ########################################################################
  # ATTRIBUTES                                                           #
  ########################################################################

  # A class that defines the set of Attributes of an Element and provides
  # operations for accessing elements in that set.
  class Attributes < Hash
    # Constructor
    # element:: the Element of which this is an Attribute
    def initialize element
      @element = element
    end

    # Fetches an attribute value.  If you want to get the Attribute itself,
    # use get_attribute()
    # name:: an XPath attribute name.  Namespaces are relevant here.
    # Returns::
    #   the String value of the matching attribute, or +nil+ if no
    #   matching attribute was found.  This is the unnormalized value
    #   (with entities expanded).
    #
    #  doc = Document.new "<a foo:att='1' bar:att='2' att='&lt;'/>"
    #  doc.root.attributes['att']         #-> '<'
    #  doc.root.attributes['bar:att']     #-> '2'
    def [](name)
      attr = get_attribute(name)
      return attr.value unless attr.nil?
      return nil
    end

    def to_a
      enum_for(:each_attribute).to_a
    end

    # Returns the number of attributes the owning Element contains.
    #  doc = Document "<a x='1' y='2' foo:x='3'/>"
    #  doc.root.attributes.length        #-> 3
    def length
      c = 0
      each_attribute { c+=1 }
      c
    end
    alias :size :length

    # Iterates over the attributes of an Element.  Yields actual Attribute
    # nodes, not String values.
    #
    #  doc = Document.new '<a x="1" y="2"/>'
    #  doc.root.attributes.each_attribute {|attr|
    #    p attr.expanded_name+" => "+attr.value
    #  }
    def each_attribute # :yields: attribute
      return to_enum(__method__) unless block_given?
      each_value do |val|
        if val.kind_of? Attribute
          yield val
        else
          val.each_value { |atr| yield atr }
        end
      end
    end

    # Iterates over each attribute of an Element, yielding the expanded name
    # and value as a pair of Strings.
    #
    #  doc = Document.new '<a x="1" y="2"/>'
    #  doc.root.attributes.each {|name, value| p name+" => "+value }
    def each
      return to_enum(__method__) unless block_given?
      each_attribute do |attr|
        yield [attr.expanded_name, attr.value]
      end
    end

    # Fetches an attribute
    # name::
    #   the name by which to search for the attribute.  Can be a
    #   <tt>prefix:name</tt> namespace name.
    # Returns:: The first matching attribute, or nil if there was none.  This
    # value is an Attribute node, not the String value of the attribute.
    #  doc = Document.new '<a x:foo="1" foo="2" bar="3"/>'
    #  doc.root.attributes.get_attribute("foo").value    #-> "2"
    #  doc.root.attributes.get_attribute("x:foo").value  #-> "1"
    def get_attribute( name )
      attr = fetch( name, nil )
      if attr.nil?
        return nil if name.nil?
        # Look for prefix
        name =~ Namespace::NAMESPLIT
        prefix, n = $1, $2
        if prefix
          attr = fetch( n, nil )
          # check prefix
          if attr == nil
          elsif attr.kind_of? Attribute
            return attr if prefix == attr.prefix
          else
            attr = attr[ prefix ]
            return attr
          end
        end
        element_document = @element.document
        if element_document and element_document.doctype
          expn = @element.expanded_name
          expn = element_document.doctype.name if expn.size == 0
          attr_val = element_document.doctype.attribute_of(expn, name)
          return Attribute.new( name, attr_val ) if attr_val
        end
        return nil
      end
      if attr.kind_of? Hash
        attr = attr[ @element.prefix ]
      end
      return attr
    end

    # Sets an attribute, overwriting any existing attribute value by the
    # same name.  Namespace is significant.
    # name:: the name of the attribute
    # value::
    #   (optional) If supplied, the value of the attribute.  If
    #   nil, any existing matching attribute is deleted.
    # Returns::
    #   Owning element
    #  doc = Document.new "<a x:foo='1' foo='3'/>"
    #  doc.root.attributes['y:foo'] = '2'
    #  doc.root.attributes['foo'] = '4'
    #  doc.root.attributes['x:foo'] = nil
    def []=( name, value )
      if value.nil?             # Delete the named attribute
        attr = get_attribute(name)
        delete attr
        return
      end

      unless value.kind_of? Attribute
        if @element.document and @element.document.doctype
          value = Text::normalize( value, @element.document.doctype )
        else
          value = Text::normalize( value, nil )
        end
        value = Attribute.new(name, value)
      end
      value.element = @element
      old_attr = fetch(value.name, nil)
      if old_attr.nil?
        store(value.name, value)
      elsif old_attr.kind_of? Hash
        old_attr[value.prefix] = value
      elsif old_attr.prefix != value.prefix
        # Check for conflicting namespaces
        if value.prefix != "xmlns" and old_attr.prefix != "xmlns"
          old_namespace = old_attr.namespace
          new_namespace = value.namespace
          if old_namespace == new_namespace
            raise ParseException.new(
                    "Namespace conflict in adding attribute \"#{value.name}\": "+
                    "Prefix \"#{old_attr.prefix}\" = \"#{old_namespace}\" and "+
                    "prefix \"#{value.prefix}\" = \"#{new_namespace}\"")
          end
        end
        store value.name, {old_attr.prefix => old_attr,
                           value.prefix    => value}
      else
        store value.name, value
      end
      return @element
    end

    # Returns an array of Strings containing all of the prefixes declared
    # by this set of # attributes.  The array does not include the default
    # namespace declaration, if one exists.
    #  doc = Document.new("<a xmlns='foo' xmlns:x='bar' xmlns:y='twee' "+
    #        "z='glorp' p:k='gru'/>")
    #  prefixes = doc.root.attributes.prefixes    #-> ['x', 'y']
    def prefixes
      ns = []
      each_attribute do |attribute|
        ns << attribute.name if attribute.prefix == 'xmlns'
      end
      if @element.document and @element.document.doctype
        expn = @element.expanded_name
        expn = @element.document.doctype.name if expn.size == 0
        @element.document.doctype.attributes_of(expn).each {
          |attribute|
          ns << attribute.name if attribute.prefix == 'xmlns'
        }
      end
      ns
    end

    def namespaces
      namespaces = {}
      each_attribute do |attribute|
        namespaces[attribute.name] = attribute.value if attribute.prefix == 'xmlns' or attribute.name == 'xmlns'
      end
      if @element.document and @element.document.doctype
        expn = @element.expanded_name
        expn = @element.document.doctype.name if expn.size == 0
        @element.document.doctype.attributes_of(expn).each {
          |attribute|
          namespaces[attribute.name] = attribute.value if attribute.prefix == 'xmlns' or attribute.name == 'xmlns'
        }
      end
      namespaces
    end

    # Removes an attribute
    # attribute::
    #   either a String, which is the name of the attribute to remove --
    #   namespaces are significant here -- or the attribute to remove.
    # Returns:: the owning element
    #  doc = Document.new "<a y:foo='0' x:foo='1' foo='3' z:foo='4'/>"
    #  doc.root.attributes.delete 'foo'   #-> <a y:foo='0' x:foo='1' z:foo='4'/>"
    #  doc.root.attributes.delete 'x:foo' #-> <a y:foo='0' z:foo='4'/>"
    #  attr = doc.root.attributes.get_attribute('y:foo')
    #  doc.root.attributes.delete attr    #-> <a z:foo='4'/>"
    def delete( attribute )
      name = nil
      prefix = nil
      if attribute.kind_of? Attribute
        name = attribute.name
        prefix = attribute.prefix
      else
        attribute =~ Namespace::NAMESPLIT
        prefix, name = $1, $2
        prefix = '' unless prefix
      end
      old = fetch(name, nil)
      if old.kind_of? Hash # the supplied attribute is one of many
        old.delete(prefix)
        if old.size == 1
          repl = nil
          old.each_value{|v| repl = v}
          store name, repl
        end
      elsif old.nil?
        return @element
      else # the supplied attribute is a top-level one
        super(name)
      end
      @element
    end

    # Adds an attribute, overriding any existing attribute by the
    # same name.  Namespaces are significant.
    # attribute:: An Attribute
    def add( attribute )
      self[attribute.name] = attribute
    end

    alias :<< :add

    # Deletes all attributes matching a name.  Namespaces are significant.
    # name::
    #   A String; all attributes that match this path will be removed
    # Returns:: an Array of the Attributes that were removed
    def delete_all( name )
      rv = []
      each_attribute { |attribute|
        rv << attribute if attribute.expanded_name == name
      }
      rv.each{ |attr| attr.remove }
      return rv
    end

    # The +get_attribute_ns+ method retrieves a method by its namespace
    # and name. Thus it is possible to reliably identify an attribute
    # even if an XML processor has changed the prefix.
    #
    # Method contributed by Henrik Martensson
    def get_attribute_ns(namespace, name)
      result = nil
      each_attribute() { |attribute|
        if name == attribute.name &&
          namespace == attribute.namespace() &&
          ( !namespace.empty? || !attribute.fully_expanded_name.index(':') )
          # foo will match xmlns:foo, but only if foo isn't also an attribute
          result = attribute if !result or !namespace.empty? or
                                !attribute.fully_expanded_name.index(':')
        end
      }
      result
    end
  end
end
