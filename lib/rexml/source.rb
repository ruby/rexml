# coding: US-ASCII
# frozen_string_literal: false
require_relative 'encoding'

module REXML
  # Generates Source-s.  USE THIS CLASS.
  class SourceFactory
    # Generates a Source object
    # @param arg Either a String, or an IO
    # @return a Source, or nil if a bad argument was given
    def SourceFactory::create_from(arg)
      if arg.respond_to? :read and
          arg.respond_to? :readline and
          arg.respond_to? :nil? and
          arg.respond_to? :eof?
        IOSource.new(arg)
      elsif arg.respond_to? :to_str
        require 'stringio'
        IOSource.new(StringIO.new(arg))
      elsif arg.kind_of? Source
        arg
      else
        raise "#{arg.class} is not a valid input stream.  It must walk \n"+
          "like either a String, an IO, or a Source."
      end
    end
  end

  # A Source can be searched for patterns, and wraps buffers and other
  # objects and provides consumption of text
  class Source
    include Encoding
    # The current buffer (what we're going to read next)
    attr_reader :buffer
    # The line number of the last consumed text
    attr_reader :line
    attr_reader :encoding

    # Constructor
    # @param arg must be a String, and should be a valid XML document
    # @param encoding if non-null, sets the encoding of the source to this
    # value, overriding all encoding detection
    def initialize(arg, encoding=nil)
      @orig = @buffer = arg
      @scanner = StringScanner.new(@buffer)
      if encoding
        self.encoding = encoding
      else
        detect_encoding
      end
      @line = 0
    end


    # Inherited from Encoding
    # Overridden to support optimized en/decoding
    def encoding=(enc)
      return unless super
      encoding_updated
    end

    def read
    end

    def match(pattern, cons=false)
      @scanner.string = @buffer
      @scanner.scan(pattern)
      @buffer = @scanner.rest if cons and @scanner.matched?

      @scanner.matched? ? [@scanner.matched, *@scanner.captures] : nil
    end

    # @return true if the Source is exhausted
    def empty?
      @buffer == ""
    end

    # @return the current line in the source
    def current_line
      lines = @orig.split
      res = lines.grep @buffer[0..30]
      res = res[-1] if res.kind_of? Array
      lines.index( res ) if res
    end

    private
    def detect_encoding
      buffer_encoding = @buffer.encoding
      detected_encoding = "UTF-8"
      begin
        @buffer.force_encoding("ASCII-8BIT")
        if @buffer[0, 2] == "\xfe\xff"
          @buffer[0, 2] = ""
          detected_encoding = "UTF-16BE"
        elsif @buffer[0, 2] == "\xff\xfe"
          @buffer[0, 2] = ""
          detected_encoding = "UTF-16LE"
        elsif @buffer[0, 3] == "\xef\xbb\xbf"
          @buffer[0, 3] = ""
          detected_encoding = "UTF-8"
        end
      ensure
        @buffer.force_encoding(buffer_encoding)
      end
      self.encoding = detected_encoding
    end

    def encoding_updated
      if @encoding != 'UTF-8'
        @buffer = decode(@buffer)
        @to_utf = true
      else
        @to_utf = false
        @buffer.force_encoding ::Encoding::UTF_8
      end
    end
  end

  # A Source that wraps an IO.  See the Source class for method
  # documentation
  class IOSource < Source
    #attr_reader :block_size

    # block_size has been deprecated
    def initialize(arg, block_size=500, encoding=nil)
      @er_source = @source = arg
      @to_utf = false
      @pending_buffer = nil

      if encoding
        super("", encoding)
      else
        super(@source.read(3) || "")
      end

      if !@to_utf and
          @buffer.respond_to?(:force_encoding) and
          @source.respond_to?(:external_encoding) and
          @source.external_encoding != ::Encoding::UTF_8
        @force_utf8 = true
      else
        @force_utf8 = false
      end
    end

    def read
      begin
        @buffer << readline
      rescue Exception, NameError
        @source = nil
      end
    end

    def match( pattern, cons=false )
      @scanner.string = @buffer
      @scanner.scan(pattern)
      @buffer = @scanner.rest if cons and @scanner.matched?
      while !@scanner.matched? and @source
        begin
          @buffer << readline
          @scanner.string = @buffer
          @scanner.scan(pattern)
          @buffer = @scanner.rest if cons and @scanner.matched?
        rescue
          @source = nil
        end
      end

      @scanner.matched? ? [@scanner.matched, *@scanner.captures] : nil
    end

    def empty?
      super and ( @source.nil? || @source.eof? )
    end

    # @return the current line in the source
    def current_line
      begin
        pos = @er_source.pos        # The byte position in the source
        lineno = @er_source.lineno  # The XML < position in the source
        @er_source.rewind
        line = 0                    # The \r\n position in the source
        begin
          while @er_source.pos < pos
            @er_source.readline
            line += 1
          end
        rescue
        end
        @er_source.seek(pos)
      rescue IOError
        pos = -1
        line = -1
      end
      [pos, lineno, line]
    end

    private
    def readline
      str = @source.readline(@line_break)
      if @pending_buffer
        if str.nil?
          str = @pending_buffer
        else
          str = @pending_buffer + str
        end
        @pending_buffer = nil
      end
      return nil if str.nil?

      if @to_utf
        decode(str)
      else
        str.force_encoding(::Encoding::UTF_8) if @force_utf8
        str
      end
    end

    def encoding_updated
      case @encoding
      when "UTF-16BE", "UTF-16LE"
        @source.binmode
        @source.set_encoding(@encoding, @encoding)
      end
      @line_break = encode(">")
      @pending_buffer, @buffer = @buffer, ""
      @pending_buffer.force_encoding(@encoding)
      super
    end
  end
end
