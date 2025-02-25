require "./tokenizer"
require "./document"
require "./node"
require "./value"

module KDL
  class Parser
    private getter parse_comments
    private getter first_comment : String?

    class Error < Exception
      def initialize(message, line, column)
        super("#{message} (#{line}:#{column})")
      end
    end

    def initialize(*, @parse_comments = true)
      @tokenizer = KDL::Tokenizer.new("")
      @depth = 0
      @first_comment = nil
    end

    def parse(string : String)
      @tokenizer = KDL::Tokenizer.new(string)
      parse_document
    end

    private def parse_document
      comment = parse_document_comment
      nodes = parse_nodes
      linespace_star
      expect_eof
      KDL::Document.new(nodes, comment: comment)
    end

    private def parse_nodes
      nodes = [] of KDL::Node
      n : Tuple(Bool, KDL::Node?)
      while (n = parse_node)[0]
        node = n[1]
        nodes << node unless node.nil?
      end
      nodes
    end

    private def parse_node
      comment = @first_comment || linespace_star
      @first_comment = nil

      commented = false
      if @tokenizer.peek_token.type == KDL::Token::Type::SLASHDASH
        parse_slashdash
        commented = true
      end

      node : KDL::Node
      type : String?
      begin
        type = parse_type
        node = KDL::Node.new(identifier, comment: comment)
      rescue error
        raise_error error unless type.nil?
        return {false, nil}
      end

      parse_args_props_children(node)

      return {true, nil} if commented

      unless type.nil?
        return {true, node.as_type(type)} # TODO: type parsers
      end

      {true, node}
    end

    private def identifier
      t = @tokenizer.peek_token
      case t.type
      when KDL::Token::Type::IDENT, KDL::Token::Type::STRING, KDL::Token::Type::RAWSTRING
        @tokenizer.next_token
        t.value.as(String)
      else
        raise_error "Expected identifier, got #{t.type}", t
      end
    end

    private def ws_star
      lines = [] of String
      while @tokenizer.peek_token.type == KDL::Token::Type::WS
        t = @tokenizer.next_token
        if c = t.comment
          lines << c
        end
      end
      return nil unless @parse_comments

      lines.empty? ? nil : lines.join("\n")
    end

    private def linespace_star
      lines = [] of String
      while linespace?(@tokenizer.peek_token)
        t = @tokenizer.next_token
        if c = t.comment
          lines << c
        elsif t.type == KDL::Token::Type::NEWLINE
          lines = [] of String
        end
      end
      return nil unless @parse_comments

      lines.empty? ? nil : lines.join("\n")
    end

    private def linespace?(t : KDL::Token)
      t.type == KDL::Token::Type::NEWLINE || t.type == KDL::Token::Type::WS
    end

    private def parse_args_props_children(node : KDL::Node)
      commented = false
      has_children = false
      loop do
        peek = @tokenizer.peek_token
        case peek.type
        when ->(x : KDL::Token::Type) { commented }, KDL::Token::Type::WS
          comment = ws_star
          peek = @tokenizer.peek_token
          if !commented && peek.type == KDL::Token::Type::SLASHDASH
            parse_slashdash
            peek = @tokenizer.peek_token
            commented = true
          end
          case peek.type
          when KDL::Token::Type::STRING, KDL::Token::Type::IDENT
            raise_error "Unexpected #{peek.type}", peek if has_children
            t = @tokenizer.peek_token_after_next
            if t.type == KDL::Token::Type::EQUALS
              p = parse_prop(comment)
              node.properties[p[0]] = p[1] unless commented
            else
              v = parse_value(comment)
              node.arguments << v unless commented
            end
            commented = false
          when KDL::Token::Type::NEWLINE, KDL::Token::Type::EOF, KDL::Token::Type::SEMICOLON
            @tokenizer.next_token
            return
          when KDL::Token::Type::LBRACE
            parse_lbrace(node, commented)
            has_children = true
            commented = false
          when KDL::Token::Type::RBRACE
            parse_rbrace
            return
          else
            v = parse_value(comment)
            raise_error "Unexpected #{peek.type}", peek if has_children
            node.arguments << v unless commented
            commented = false
          end
        when KDL::Token::Type::EOF, KDL::Token::Type::SEMICOLON, KDL::Token::Type::NEWLINE
          @tokenizer.next_token
          return
        when KDL::Token::Type::LBRACE
          parse_lbrace(node, commented)
          has_children = true
          commented = false
        when KDL::Token::Type::RBRACE
          parse_rbrace
          return
        when KDL::Token::Type::SLASHDASH
          parse_slashdash
          commented = true
        else
          raise_error "Unexpected #{peek.type} (#{peek.value})", peek
        end
      end
    end

    private def parse_lbrace(node, commented)
      raise_error "Unexpected {" if !commented && node.children?
      @depth += 1
      children = parse_children
      @depth -= 1
      node.children = KDL::Document.new(children) unless commented
    end

    private def parse_rbrace
      raise_error "Unexpected }" if @depth.zero?
    end

    private def parse_prop(comment)
      name = identifier
      expect(KDL::Token::Type::EQUALS)
      value = parse_value(comment)
      return {name, value}
    end

    private def parse_children
      expect(KDL::Token::Type::LBRACE)
      nodes = parse_nodes
      linespace_star
      expect(KDL::Token::Type::RBRACE)
      nodes
    end

    private def parse_value(comment)
      type = parse_type
      t = @tokenizer.next_token
      v = value_without_type(t)
      v.comment = comment
      return v if type.nil?
      v.as_type(type) # TODO: type parser
    end

    private def value_without_type(t)
      case t.type
      when KDL::Token::Type::IDENT,
           KDL::Token::Type::STRING,
           KDL::Token::Type::RAWSTRING,
           KDL::Token::Type::INTEGER,
           KDL::Token::Type::DECIMAL,
           KDL::Token::Type::FLOAT,
           KDL::Token::Type::TRUE,
           KDL::Token::Type::FALSE,
           KDL::Token::Type::NULL
        return KDL::Value.new(t.value, format: t.meta[:format]?)
      else
        raise_error "Expected value, got #{t.type}", t
      end
    end

    private def parse_type
      return nil unless @tokenizer.peek_token.type == KDL::Token::Type::LPAREN
      expect(KDL::Token::Type::LPAREN)
      ws_star
      type = identifier
      ws_star
      expect(KDL::Token::Type::RPAREN)
      ws_star
      type
    end

    private def parse_document_comment
      return nil unless @parse_comments

      lines = [] of String
      while linespace?(@tokenizer.peek_token)
        t = @tokenizer.next_token
        if c = t.comment
          lines << c
        else
          return lines.empty? ? nil : lines.join("\n")
        end
      end
      @first_comment = lines.empty? ? nil : lines.join("\n")
      nil
    end

    private def parse_slashdash
      t = @tokenizer.next_token
      raise_error "Expected SLASHDASH, found #{t.type}", t unless t.type == KDL::Token::Type::SLASHDASH
      linespace_star
      peek = @tokenizer.peek_token
      case peek.type
      when KDL::Token::Type::RBRACE, KDL::Token::Type::EOF, KDL::Token::Type::SEMICOLON
        raise_error "Unexpected #{peek.type} after SLASHDASH", peek
      end
    end

    private def expect(type : KDL::Token::Type)
      t = @tokenizer.peek_token
      raise_error "Expected #{type}, got #{t.type}", t unless t.type == type

      @tokenizer.next_token
    end

    private def expect_node_term
      ws_star
      t = @tokenizer.peek_token.type
      case t
      when KDL::Token::Type::NEWLINE, KDL::Token::Type::SEMICOLON, KDL::Token::Type::EOF
        @tokenizer.next_token
      when KDL::Token::Type::RBRACE
        return
      else
        raise_error "Unexpected #{t}", t
      end
    end

    private def expect_eof
      t = @tokenizer.peek_token
      case t.type
      when KDL::Token::Type::EOF
        return
      else
        raise_error "Expected EOF, got #{t.type}", t
      end
    end

    private def raise_error(error, token = nil)
      line : Int32
      column : Int32
      if token.nil?
        line = @tokenizer.line
        column = @tokenizer.column
      else
        line = token.line
        column = token.column
      end
      case error
      when String then raise Error.new(error, line, column)
      when Error  then raise error
      else             raise Error.new(error.message, line, column)
      end
    end
  end
end
