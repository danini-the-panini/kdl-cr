require "./tokenizer"
require "./document"
require "./node"
require "./value"

module KDL
  class Parser
    def initialize
      @tokenizer = KDL::Tokenizer.new("")
      @depth = 0
    end

    def parse(string : String)
      @tokenizer = KDL::Tokenizer.new(string)
      parse_document
    end

    private def parse_document
      nodes = parse_nodes
      linespace_star
      expect_eof
      KDL::Document.new(nodes)
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
      linespace_star

      commented = false

      if @tokenizer.peek_token.type == KDL::Token::Type::SLASHDASH
        @tokenizer.next_token
        ws_star
        commented = true
      end

      node : KDL::Node
      type : String?
      begin
        type = parse_type
        node = KDL::Node.new(identifier)
      rescue error
        raise error unless type.nil?
        return {false, nil}
      end

      node.type = type

      case @tokenizer.peek_token.type
      when KDL::Token::Type::WS, KDL::Token::Type::LBRACE
        args_props_children(node)
      when KDL::Token::Type::SEMICOLON
        @tokenizer.next_token
      when KDL::Token::Type::LPAREN
        raise "Unexpected ("
      end

      return {true, nil} if commented

      {true, node}
    end

    private def identifier
      t = @tokenizer.peek_token
      case t.type
      when KDL::Token::Type::IDENT, KDL::Token::Type::STRING, KDL::Token::Type::RAWSTRING
        @tokenizer.next_token
        t.value.as(String)
      else
        raise "Expected identifier, got #{t.type}"
      end
    end

    private def ws_star
      while @tokenizer.peek_token.type == KDL::Token::Type::WS
        @tokenizer.next_token
      end
    end

    private def linespace_star
      while linespace?(@tokenizer.peek_token)
        @tokenizer.next_token
      end
    end

    private def linespace?(t : KDL::Token)
      t.type == KDL::Token::Type::NEWLINE || t.type == KDL::Token::Type::WS
    end

    private def args_props_children(node : KDL::Node)
      commented = false
      loop do
        ws_star
        case @tokenizer.peek_token.type
        when KDL::Token::Type::IDENT
          t = @tokenizer.peek_token_after_next
          if t.type == KDL::Token::Type::EQUALS
            prop = parse_prop
            node.properties[prop[0]] = prop[1] unless commented
          else
            value = parse_value
            node.arguments << value unless commented
          end
          commented = false
        when KDL::Token::Type::LBRACE
          @depth += 1
          children = parse_children
          node.children = children unless commented
          expect_node_term
          return
        when KDL::Token::Type::RBRACE
          raise "Unexpected }" if @depth.zero?
          @depth -= 1
          return
        when KDL::Token::Type::SLASHDASH
          commented = true
          @tokenizer.next_token
          ws_star
        when KDL::Token::Type::NEWLINE, KDL::Token::Type::EOF, KDL::Token::Type::SEMICOLON
          @tokenizer.next_token
          return
        when KDL::Token::Type::STRING
          t = @tokenizer.peek_token_after_next
          case t.type
          when KDL::Token::Type::EQUALS
            prop = parse_prop
            node.properties[prop[0]] = prop[1] unless commented
          else
            value = parse_value
            node.arguments << value unless commented
          end
          commented = false
        else
          value = parse_value
          node.arguments << value unless commented
          commented = false
        end
      end
    end

    private def parse_prop
      name = identifier
      expect(KDL::Token::Type::EQUALS)
      value = parse_value
      return {name, value}
    end

    private def parse_children
      expect(KDL::Token::Type::LBRACE)
      nodes = parse_nodes
      linespace_star
      expect(KDL::Token::Type::RBRACE)
      nodes
    end

    private def parse_value
      type = parse_type
      t = @tokenizer.next_token
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

        return KDL::Value.new(t.value, type: type)
      else
        raise "Expected value, got #{t.type}"
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

    private def expect(type : KDL::Token::Type)
      t = @tokenizer.peek_token.type
      raise "Expected #{type}, got #{t}" unless t == type

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
        raise "Unexpected #{t}"
      end
    end

    private def expect_eof
      t = @tokenizer.peek_token.type
      case t
      when KDL::Token::Type::EOF, KDL::Token::Type::NONE
        return
      else
        raise "Expected EOF, got #{t}"
      end
    end
  end
end