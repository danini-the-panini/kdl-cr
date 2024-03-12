require "../spec_helper"

describe KDL::Tokenizer do
  describe "#peek and #peek_after_next" do
    it "returns next token and token after" do
      tokenizer = KDL::Tokenizer.new("node 1 2 3")
  
      tokenizer.peek_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "node"))
      tokenizer.peek_token_after_next.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "node"))
      tokenizer.peek_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.peek_token_after_next.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 1_i64))
    end
  end

  describe "#next_token" do
    it "tokenizes identifier" do
      KDL::Tokenizer.new("foo").next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "foo"))
      KDL::Tokenizer.new("foo-bar123").next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "foo-bar123"))
      KDL::Tokenizer.new("-").next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "-"))
      KDL::Tokenizer.new("--").next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "--"))
    end

    it "tokenizes string" do
      KDL::Tokenizer.new(%("foo")).next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "foo"))
      KDL::Tokenizer.new(%("foo\\nbar")).next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "foo\nbar"))
      KDL::Tokenizer.new(%("\\u{10FFF}")).next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "\u{10FFF}"))
    end

    it "tokenizes multiline string" do
      KDL::Tokenizer.new(%("foo\nbar")).next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "foo\nbar"))
      KDL::Tokenizer.new(%("\n  foo\n  bar\n  ")).next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "foo\nbar"))
      KDL::Tokenizer.new(%(#"foo\nbar"#)).next_token.should eq(KDL::Token.new(KDL::Token::Type::RAWSTRING, "foo\nbar"))
      KDL::Tokenizer.new(%(#"\n  foo\n  bar\n  "#)).next_token.should eq(KDL::Token.new(KDL::Token::Type::RAWSTRING, "foo\nbar"))
    end

    it "tokenizes rawstring" do
      KDL::Tokenizer.new(%(#"foo\\nbar"#)).next_token.should eq(KDL::Token.new(KDL::Token::Type::RAWSTRING, "foo\\nbar"))
      KDL::Tokenizer.new(%(#"foo"bar"#)).next_token.should eq(KDL::Token.new(KDL::Token::Type::RAWSTRING, "foo\"bar"))
      KDL::Tokenizer.new(%(##"foo"#bar"##)).next_token.should eq(KDL::Token.new(KDL::Token::Type::RAWSTRING, "foo\"#bar"))
      KDL::Tokenizer.new(%(#""foo""#)).next_token.should eq(KDL::Token.new(KDL::Token::Type::RAWSTRING, "\"foo\""))
  
      tokenizer = KDL::Tokenizer.new(%(node #"C:\\Users\\zkat\\"#))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "node"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::RAWSTRING, "C:\\Users\\zkat\\"))
  
      tokenizer = KDL::Tokenizer.new(%(other-node #"hello"world"#))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "other-node"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::RAWSTRING, "hello\"world"))
    end

    it "tokenizes integer" do
      KDL::Tokenizer.new("123").next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 123_i64))
      KDL::Tokenizer.new("0x0123456789abcdef").next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 0x0123456789abcdef))
      KDL::Tokenizer.new("0x0123456789ABCDEF").next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 0x0123456789ABCDEF))
      KDL::Tokenizer.new("0o01234567").next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 0o01234567i64))
      KDL::Tokenizer.new("0b010101").next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 0b010101i64))
    end
  
    it "tokenizes float" do
      KDL::Tokenizer.new("1.23").next_token.should eq(KDL::Token.new(KDL::Token::Type::FLOAT, 1.23))
      KDL::Tokenizer.new("-1.0").next_token.should eq(KDL::Token.new(KDL::Token::Type::FLOAT, -1.0))
      KDL::Tokenizer.new("#inf").next_token.should eq(KDL::Token.new(KDL::Token::Type::FLOAT, Float64::INFINITY))
      KDL::Tokenizer.new("#-inf").next_token.should eq(KDL::Token.new(KDL::Token::Type::FLOAT, -Float64::INFINITY))
      nan = KDL::Tokenizer.new("#nan").next_token.as(KDL::Token)
      nan.type.should eq KDL::Token::Type::FLOAT
      nan.value.should_not eq nan.value
    end
  
    it "tokenizes boolean" do
      KDL::Tokenizer.new("#true").next_token.should eq(KDL::Token.new(KDL::Token::Type::TRUE, true))
      KDL::Tokenizer.new("#false").next_token.should eq(KDL::Token.new(KDL::Token::Type::FALSE, false))
    end
  
    it "tokenizes null" do
      KDL::Tokenizer.new("#null").next_token.should eq(KDL::Token.new(KDL::Token::Type::NULL, nil))
    end
  
    it "tokenizes symbols" do
      KDL::Tokenizer.new("{").next_token.should eq(KDL::Token.new(KDL::Token::Type::LBRACE, "{"))
      KDL::Tokenizer.new("}").next_token.should eq(KDL::Token.new(KDL::Token::Type::RBRACE, "}"))
    end
  
    it "tokenizes equals" do
      KDL::Tokenizer.new("=").next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "="))
      KDL::Tokenizer.new(" =").next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, " ="))
      KDL::Tokenizer.new("= ").next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "= "))
      KDL::Tokenizer.new(" = ").next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, " = "))
      KDL::Tokenizer.new(" =foo").next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, " ="))
      KDL::Tokenizer.new("\uFE66").next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "\uFE66"))
      KDL::Tokenizer.new("\uFF1D").next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "\uFF1D"))
      KDL::Tokenizer.new("🟰").next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "🟰"))
    end
  
    it "tokenizes whitespace" do
      KDL::Tokenizer.new(" ").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      KDL::Tokenizer.new("\t").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "\t"))
      KDL::Tokenizer.new("    \t").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "    \t"))
      KDL::Tokenizer.new("\\\n").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "\\\n"))
      KDL::Tokenizer.new("\\").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "\\"))
      KDL::Tokenizer.new("\\//some comment\n").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "\\\n"))
      KDL::Tokenizer.new("\\ //some comment\n").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "\\ \n"))
      KDL::Tokenizer.new("\\//some comment").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "\\"))
      KDL::Tokenizer.new(" \\\n").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " \\\n"))
      KDL::Tokenizer.new(" \\//some comment\n").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " \\\n"))
      KDL::Tokenizer.new(" \\ //some comment\n").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " \\ \n"))
      KDL::Tokenizer.new(" \\//some comment").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " \\"))
      KDL::Tokenizer.new(" \\\n  \\\n  ").next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " \\\n  \\\n  "))
    end
  
    it "tokenizes multiple_tokens" do
      tokenizer = KDL::Tokenizer.new("node 1 \"two\" a=3")
  
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "node"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 1_i64))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "two"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "a"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "="))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 3_i64))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EOF, ""))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NONE, ""))
    end
  
    it "tokenizes single_line_comment" do
      KDL::Tokenizer.new("// comment").next_token.should eq(KDL::Token.new(KDL::Token::Type::EOF, ""))
  
      tokenizer = KDL::Tokenizer.new <<-KDL.strip
      node1
      // comment
      node2
      KDL
  
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "node1"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NEWLINE, "\n"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NEWLINE, "\n"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "node2"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EOF, ""))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NONE, ""))
    end
  
    it "tokenizes multiline_comment" do
      tokenizer = KDL::Tokenizer.new("foo /*bar=1*/ baz=2")
  
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "foo"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "  "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "baz"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "="))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 2_i64))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EOF, ""))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NONE, ""))
    end
  
    it "tokenizes utf8" do
      KDL::Tokenizer.new("😁").next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "😁"))
      KDL::Tokenizer.new(%("😁")).next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "😁"))
      KDL::Tokenizer.new("ノード").next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "ノード"))
      KDL::Tokenizer.new("お名前").next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "お名前"))
      KDL::Tokenizer.new(%("☜(ﾟヮﾟ☜)")).next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "☜(ﾟヮﾟ☜)"))
  
      tokenizer = KDL::Tokenizer.new <<-KDL.strip
      smile "😁"
      ノード お名前＝"☜(ﾟヮﾟ☜)"
      KDL
  
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "smile"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "😁"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NEWLINE, "\n"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "ノード"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "お名前"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "＝"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "☜(ﾟヮﾟ☜)"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EOF, ""))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NONE, ""))
    end
  
    it "tokenizes semicolon" do
      tokenizer = KDL::Tokenizer.new("node1; node2")
  
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "node1"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::SEMICOLON, ";"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "node2"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EOF, ""))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NONE, ""))
    end
  
    it "tokenizes slash_dash" do
      tokenizer = KDL::Tokenizer.new <<-KDL.strip
      /-mynode /-"foo" /-key=1 /-{
        a
      }
      KDL
  
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::SLASHDASH, "/-"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "mynode"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::SLASHDASH, "/-"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "foo"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::SLASHDASH, "/-"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "key"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EQUALS, "="))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::INTEGER, 1_i64))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::SLASHDASH, "/-"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::LBRACE, "{"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NEWLINE, "\n"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, "  "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "a"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NEWLINE, "\n"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::RBRACE, "}"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EOF, ""))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NONE, ""))
    end
  
    it "tokenizes multiline_nodes" do
      tokenizer = KDL::Tokenizer.new <<-KDL.strip
      title \\
        "Some title"
      KDL
  
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "title"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::WS, " \\\n  "))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::STRING, "Some title"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::EOF, ""))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::NONE, ""))
    end
  
    it "tokenizes types" do
      tokenizer = KDL::Tokenizer.new("(foo)bar")
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::LPAREN, "("))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "foo"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::RPAREN, ")"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "bar"))
  
      tokenizer = KDL::Tokenizer.new("(foo)/*asdf*/bar")
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::LPAREN, "("))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "foo"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::RPAREN, ")"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "bar"))
  
      tokenizer = KDL::Tokenizer.new("(foo/*asdf*/)bar")
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::LPAREN, "("))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "foo"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::RPAREN, ")"))
      tokenizer.next_token.should eq(KDL::Token.new(KDL::Token::Type::IDENT, "bar"))
    end
  end
end
