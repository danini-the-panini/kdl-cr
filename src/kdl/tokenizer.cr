require "big"

module KDL
  struct Token
    enum Type
      IDENT
      STRING
      RAWSTRING
      INTEGER
      DECIMAL
      FLOAT
      TRUE
      FALSE
      NULL
      WS
      NEWLINE
      LBRACE
      RBRACE
      LPAREN
      RPAREN
      EQUALS
      SEMICOLON
      EOF
      SLASHDASH
    end

    property type : Type
    property value : KDL::Value::Type
    property line : Int32
    property column : Int32
    property meta : Hash(Symbol, String)
    property comment : String?

    def initialize(@type, @value, @line = 1, @column = 1, @meta = {} of Symbol => String, @comment = nil)
    end

    def ==(other : self)
      other.type == type && other.value == value
    end
  end

  class Tokenizer
    class Error < Exception
      def initialize(message, line, column)
        super("#{message} (#{line}:#{column})")
      end
    end

    enum Context
      Ident
      Keyword
      String
      Rawstring
      MultiLineString
      MultiLineRawstring
      Binary
      Octal
      Hexadecimal
      Decimal
      SingleLineComment
      MultiLineComment
      Whitespace
      Equals
    end

    SYMBOLS = {
      '{' => Token::Type::LBRACE,
      '}' => Token::Type::RBRACE,
      ';' => Token::Type::SEMICOLON,
      '=' => Token::Type::EQUALS,
    }

    WHITESPACE = [
      '\u0009', '\u0020', '\u00A0', '\u1680',
      '\u2000', '\u2001', '\u2002', '\u2003',
      '\u2004', '\u2005', '\u2006', '\u2007',
      '\u2008', '\u2009', '\u200A', '\u202F',
      '\u205F', '\u3000',
    ]
    WS      = "[#{Regex.escape(WHITESPACE.join)}]"
    WS_STAR = /\A#{WS}*\z/
    WS_PLUS = /\A#{WS}+\z/

    NEWLINES         = ['\u000A', '\u0085', '\u000B', '\u000C', '\u2028', '\u2029']
    NEWLINES_PATTERN = /(#{NEWLINES.map { |c| Regex.escape(c) }.join('|')}|\r\n?)/

    OTHER_NON_IDENTIFIER_CHARS = ('\u0000'..'\u0020').to_a - WHITESPACE

    NON_IDENTIFIER_CHARS = Regex.escape "#{SYMBOLS.keys.join("")}()[]/\\\"##{WHITESPACE.join}#{OTHER_NON_IDENTIFIER_CHARS.join}"

    IDENTIFER_CHARS          = /[^#{NON_IDENTIFIER_CHARS}]/
    INITIAL_IDENTIFIER_CHARS = /[^#{NON_IDENTIFIER_CHARS}0-9]/

    FORBIDDEN = [
      *'\u0000'..'\u0008',
      *'\u000E'..'\u001F',
      '\u007F',
      *'\u200E'..'\u200F',
      *'\u202A'..'\u202E',
      *'\u2066'..'\u2069',
      '\uFEFF',
    ]

    VERSION_PATTERN = /\A\/-[#{WHITESPACE.join}]*kdl-version[#{WHITESPACE.join}]+(\d+)[#{WHITESPACE.join}]*[#{NEWLINES.join}]/

    property line
    property column
    property comment
    property has_comment

    @str : String
    @context : Context?
    @last_token : Token?
    @line_at_start : Int32
    @column_at_start : Int32

    def initialize(str : String, @start = 0)
      @str = debom(str)
      @context = nil
      @rawstring_hashes = 0
      @index = @start
      @buffer = ""
      @done = false
      @previous_context = nil
      @line = 1
      @column = 1
      @line_at_start = @line
      @column_at_start = @column
      @type_context = false
      @peeked_tokens = [] of Token?
      @last_token = nil
      @comment_nesting = 1
      @comment = ""
      @has_comment = false
    end

    def version_directive
      if m = @str.match(VERSION_PATTERN)
        m[1].to_i
      end
    end

    def index
      @index
    end

    def done?
      @done
    end

    def [](i)
      return nil if i < 0 || i >= @str.size

      @str[i].tap do |c|
        raise_error "Forbidden character: #{c.inspect}" if FORBIDDEN.includes?(c)
      end
    end

    def tokens
      a = [] of Token
      until done
        a << next_token
      end
      a
    end

    def reset
      @index = @start
    end

    def context
      @context
    end

    def peek_token
      if @peeked_tokens.empty?
        @peeked_tokens << read_next_token
      end
      @peeked_tokens.first.as(KDL::Token)
    end

    def peek_token_after_next
      if @peeked_tokens.empty?
        @peeked_tokens << read_next_token << read_next_token
      elsif @peeked_tokens.size == 1
        @peeked_tokens << read_next_token
      end
      @peeked_tokens[1].as(KDL::Token)
    end

    def next_token
      if @peeked_tokens.empty?
        read_next_token
      else
        @peeked_tokens.shift.as(KDL::Token)
      end
    end

    def read_next_token
      @context = nil
      @previous_context = nil
      @line_at_start = @line
      @column_at_start = @column
      loop do
        c = self[@index]
        case @context
        when nil
          case c
          when '"'
            @buffer = ""
            if self[@index + 1] == '"' && self[@index + 2] == '"'
              nl = expect_newline(@index + 3)
              self.context = Context::MultiLineString
              traverse(3 + nl.size)
            else
              self.context = Context::String
              traverse 1
            end
          when '#'
            case self[@index + 1]
            when '"'
              @rawstring_hashes = 1
              if self[@index + 2] == '"' && self[@index + 3] == '"'
                nl = expect_newline(@index + 4)
                self.context = Context::MultiLineRawstring
                @buffer = ""
                traverse(4 + nl.size)
                next
              else
                self.context = Context::Rawstring
                traverse 2
                @buffer = ""
                next
              end
            when '#'
              i = @index + 2
              @rawstring_hashes = 2
              while self[i] == '#'
                @rawstring_hashes += 1
                i += 1
              end
              if self[i] == '"'
                @buffer = ""
                if self[i + 1] == '"' && self[i + 2] == '"'
                  nl = expect_newline(i + 3)
                  self.context = Context::MultiLineRawstring
                  traverse(@rawstring_hashes + 3 + nl.size)
                  next
                else
                  self.context = Context::Rawstring
                  traverse(@rawstring_hashes + 1)
                  next
                end
              end
            end
            self.context = Context::Keyword
            @buffer = c.to_s
            traverse 1
          when '-'
            n = self[@index + 1]
            if /[0-9]/ === n.to_s
              n2 = self[@index + 2]
              if n == '0' && /[box]/ === n2.to_s
                self.context = integer_context(n2)
                traverse 3
              else
                self.context = Context::Decimal
                traverse 1
              end
            else
              self.context = Context::Ident
              traverse 1
            end
            @buffer = c.to_s
          when ->(c : Char?) { /[0-9+]/ === c.to_s }
            n = self[@index + 1]
            if c == '0' && (n == 'b' || n == 'o' || n == 'x')
              traverse 2
              @buffer = ""
              self.context = integer_context(n)
            else
              self.context = Context::Decimal
              @buffer = c.to_s
              traverse 1
            end
          when '\\'
            t = Tokenizer.new(@str, @index + 1)
            la = t.next_token
            if la && (la.type == Token::Type::NEWLINE || la.type == Token::Type::EOF || (la.type == Token::Type::WS && (lan = t.next_token) && (lan.type == Token::Type::NEWLINE || lan.type == Token::Type::EOF)))
              traverse_to(t.index)
              @buffer = "#{c}#{la.value}"
              @buffer += "\n" if lan && lan.type == Token::Type::NEWLINE
              self.context = Context::Whitespace
            else
              raise_error "Unexpected '\\' (#{la ? la.type : "?"})"
            end
          when '='
            self.context = Context::Equals
            @buffer = c.to_s
            traverse 1
          when ->(c : Char?) { SYMBOLS.has_key?(c) }
            return token(SYMBOLS[c], c.to_s).tap { traverse 1 }
          when ->(c : Char?) { NEWLINES.includes?(c) }, '\r'
            nl = expect_newline
            return token(Token::Type::NEWLINE, nl).tap { traverse nl.size }
          when '/'
            case self[@index + 1]
            when '/'
              self.context = Context::SingleLineComment
              @has_comment = true
              traverse 2
            when '*'
              self.context = Context::MultiLineComment
              @has_comment = true
              @comment_nesting = 1
              traverse 2
            when '-'
              return token(Token::Type::SLASHDASH, "/-").tap { traverse 2 }
            else
              self.context = Context::Ident
              @buffer = c.to_s
              traverse 1
            end
          when ->(c : Char?) { WHITESPACE.includes?(c) }
            self.context = Context::Whitespace
            @buffer = c.to_s
            traverse 1
          when ->(c : Char?) { INITIAL_IDENTIFIER_CHARS === c.to_s }
            self.context = Context::Ident
            @buffer = c.to_s
            traverse 1
          when '('
            @type_context = true
            return token(Token::Type::LPAREN, c.to_s).tap { traverse 1 }
          when ')'
            @type_context = false
            return token(Token::Type::RPAREN, c.to_s).tap { traverse 1 }
          when nil
            return token(Token::Type::EOF, "") if done?

            @done = true
            return token(Token::Type::EOF, "")
          else
            raise_error "Unexpected character #{c.inspect}"
          end
        when Context::Ident
          case c.to_s
          when IDENTIFER_CHARS
            traverse 1
            @buffer += c.to_s
          else
            case @buffer
            when "true", "false", "null", "inf", "-inf", "nan"
              raise_error "Identifier cannot be a literal"
            when /\A\.\d/
              raise_error "Identifier cannot look like an illegal float"
            else
              return token(Token::Type::IDENT, @buffer)
            end
          end
        when Context::Keyword
          case c.to_s
          when /[a-z\-]/
            traverse 1
            @buffer += c.to_s
          else
            case @buffer
            when "#true"  then return token(Token::Type::TRUE, true)
            when "#false" then return token(Token::Type::FALSE, false)
            when "#null"  then return token(Token::Type::NULL, nil)
            when "#inf"   then return token(Token::Type::FLOAT, Float64::INFINITY)
            when "#-inf"  then return token(Token::Type::FLOAT, -Float64::INFINITY)
            when "#nan"   then return token(Token::Type::FLOAT, Float64::NAN)
            else               raise_error "Unknown keyword #{@buffer}"
            end
          end
        when Context::String
          case c
          when '\\'
            @buffer += c.to_s
            c2 = self[@index + 1].to_s
            @buffer += c2
            if NEWLINES_PATTERN === c2
              i = 2
              while (c3 = self[@index + i].to_s) && NEWLINES_PATTERN === c3
                @buffer += c3
                i += 1
              end
              traverse i
            else
              traverse 2
            end
          when '"'
            return token(Token::Type::STRING, unescape(@buffer)).tap { traverse 1 }
          when ->(c : Char?) { NEWLINES.includes?(c) }, '\r'
            raise_error "Unexpected NEWLINE in string literal"
          when nil
            raise_error "Unterminated string literal"
          else
            @buffer += c.to_s
            traverse 1
          end
        when Context::MultiLineString
          case c
          when '\\'
            @buffer += c.to_s
            @buffer += self[@index + 1].to_s
            traverse 2
          when '"'
            if self[@index + 1] == '"' && self[@index + 2] == '"'
              return token(Token::Type::STRING, unescape_non_ws(dedent(unescape_ws(@buffer)))).tap { traverse 3 }
            end
            @buffer += c.to_s
            traverse 1
          when nil
            raise_error "Unterminated multi-line string literal"
          else
            @buffer += c.to_s
            traverse 1
          end
        when Context::Rawstring
          raise_error "Unterminated rawstring literal" if c.nil?

          case c
          when '"'
            h = 0
            while self[@index + 1 + h] == '#' && h < @rawstring_hashes
              h += 1
            end
            if h == @rawstring_hashes
              return token(Token::Type::RAWSTRING, @buffer).tap { traverse 1 + h }
            end
          when ->(c : Char?) { NEWLINES.includes? c }, '\r'
            raise_error "Unexpected NEWLINE in rawstring literal"
          end

          @buffer += c
          traverse 1
        when Context::MultiLineRawstring
          raise_error "Unterminated multi-line rawstring literal" if c.nil?

          if c == '"' && self[@index + 1] == '"' && self[@index + 2] == '"' && self[@index + 3] == '#'
            h = 1
            while self[@index + 3 + h] == '#' && h < @rawstring_hashes
              h += 1
            end
            if h == @rawstring_hashes
              return token(Token::Type::RAWSTRING, dedent(@buffer)).tap { traverse(3 + h) }
            end
          end

          @buffer += c.to_s
          traverse 1
        when Context::Decimal
          case c.to_s
          when /[0-9.\-+_eE]/
            traverse 1
            @buffer += c.to_s
          else
            return parse_decimal(@buffer)
          end
        when Context::Hexadecimal
          case c.to_s
          when /[0-9a-fA-F_]/
            traverse 1
            @buffer += c.to_s
          else
            return parse_hexadecimal(@buffer)
          end
        when Context::Octal
          case c.to_s
          when /[0-7_]/
            traverse 1
            @buffer += c.to_s
          else
            return parse_octal(@buffer)
          end
        when Context::Binary
          case c.to_s
          when /[01_]/
            traverse 1
            @buffer += c.to_s
          else
            return parse_binary(@buffer)
          end
        when Context::SingleLineComment
          if NEWLINES.includes?(c) || c == '\r'
            @comment += "\n"
            self.context = nil
            @column_at_start = @column
            next
          elsif c.nil?
            @done = true
            return token(Token::Type::EOF, "")
          else
            @comment += c.to_s
            traverse 1
          end
        when Context::MultiLineComment
          if c == '/' && self[@index + 1] == '*'
            @comment += "/*"
            @comment_nesting += 1
            traverse 2
          elsif c == '*' && self[@index + 1] == '/'
            @comment_nesting -= 1
            traverse 2
            if @comment_nesting == 0
              revert_context
            else
              @comment += "*/"
            end
          else
            @comment += c.to_s
            traverse 1
          end
        when Context::Whitespace
          if WHITESPACE.includes?(c)
            traverse 1
            @buffer += c.to_s
          elsif c == '='
            self.context = Context::Equals
            @buffer += c.to_s
            traverse 1
          elsif c == '/' && self[@index + 1] == '*'
            self.context = Context::MultiLineComment
            @has_comment = true
            @comment_nesting = 1
            traverse 2
          elsif c == '\\'
            t = Tokenizer.new(@str, @index + 1)
            la = t.next_token
            if la && (la.type == Token::Type::NEWLINE || la.type == Token::Type::EOF || (la.type == Token::Type::WS && (lan = t.next_token) && (lan.type == Token::Type::NEWLINE || lan == Token::Type::EOF)))
              traverse_to t.index
              @buffer += "#{c}#{la.value}"
              @buffer += "\n" if lan && lan.type == Token::Type::NEWLINE
            else
              raise_error "Unexpected '\\' (#{la ? la.type : "?"})"
            end
          else
            return token(Token::Type::WS, @buffer)
          end
        when Context::Equals
          t = Tokenizer.new(@str, @index)
          la = t.next_token
          if la && la.type == Token::Type::WS
            @buffer += la.value.as(String)
            traverse_to t.index
          end
          return token(Token::Type::EQUALS, @buffer)
        end
      end
    end

    private def token(type, value, meta = {} of Symbol => String)
      token = Token.new(type, value, @line_at_start, @column_at_start, meta, has_comment ? comment.strip : nil)
      @has_comment = false
      @comment = ""
      @last_token = token unless type == Token::Type::EOF
      token
    end

    private def traverse(n = 1)
      n.times do |i|
        case self[@index + i]
        when '\r'
          @column = 1
        when ->(c : Char?) { NEWLINES.includes? c }
          @line += 1
          @column = 1
        else
          @column += 1
        end
      end
      @index += n
    end

    private def traverse_to(i)
      traverse(i - @index)
    end

    private def raise_error(error)
      case error
      when String then raise Error.new(error, @line, @column)
      when Error  then raise error
      else             raise Error.new(error.message, @line, @column)
      end
    end

    private def context=(val)
      if @type_context && !allowed_in_type?(val)
        raise_error "#{val} context not allowed in type declaration"
      elsif @last_token == Token::Type::RPAREN && !allowed_after_type?(val)
        raise_error "#{val} context is not allowed after a type declaration"
      end
      @previous_context = @context
      @context = val
    end

    private def revert_context
      @context = @previous_context
      @previous_context = nil
    end

    private def allowed_in_type?(val)
      [
        Context::Ident,
        Context::String,
        Context::Rawstring,
        Context::MultiLineComment,
        Context::Whitespace,
      ].includes? val
    end

    private def allowed_after_type?(val)
      val != Context::SingleLineComment
    end

    private def expect_newline(i = @index)
      c = self[i]
      case c
      when '\r'
        n = self[i + 1]
        if n == '\n'
          "#{c}#{n}"
        else
          c.to_s
        end
      when ->(c : Char?) { NEWLINES.includes? c }
        c.to_s
      else
        raise_error "Expected NEWLINE, found #{c}"
      end
    end

    private def integer_context(n)
      case n
      when 'b' then Context::Binary
      when 'o' then Context::Octal
      when 'x' then Context::Hexadecimal
      end
    end

    private def parse_decimal(s)
      return parse_float(s) if s =~ /[.E]/i

      token(Token::Type::INTEGER, Int64.new(munch_underscores(s), 10), {:format => "%d"})
    rescue e
      if INITIAL_IDENTIFIER_CHARS === s[0].to_s && s[1..-1].each_char.all? { |c| IDENTIFER_CHARS === c.to_s }
        token(Token::Type::IDENT, s)
      else
        raise_error e
      end
    end

    private def parse_float(s)
      m = s.match(/^([-+]?[\d_]+)(?:\.(\d[\d_]*))?(?:[eE]([-+]?[\d_]+))?$/)
      raise_error "Invalid floating point value #{s}" if m.nil?

      match = m[0]?
      fraction = m[2]?
      exponent = m[3]?

      s = munch_underscores(s)
      exponent = munch_underscores(exponent) if exponent

      decimals = fraction.nil? ? 0 : fraction.size
      value = try_parse_float(s)
      scientific = value ? value.abs >= 100 || (exponent && exponent.to_i.abs >= 2) : false
      if value.nil? || value.infinite? || value.nan? || (value.zero? && scientific)
        token(Token::Type::DECIMAL, BigDecimal.new(s))
      else
        token(Token::Type::FLOAT, value, {:format => scientific ? "%.#{decimals}E" : nil}.compact)
      end
    end

    private def try_parse_float(s)
      Float64.new(s)
    rescue ArgumentError
      nil
    end

    private def parse_hexadecimal(s)
      raise_error "Invalid hexadecimal value '#{s}'" unless /^[a-fA-F0-9][a-fA-F0-9_]*$/ =~ s

      token(Token::Type::INTEGER, parse_int(munch_underscores(s), 16))
    end

    private def parse_octal(s)
      raise_error "Invalid octal value '#{s}'" unless /^[0-7][0-7_]*$/ =~ s

      token(Token::Type::INTEGER, parse_int(munch_underscores(s), 8))
    end

    private def parse_binary(s)
      raise_error "Invalid binary value '#{s}'" unless /^[01][01_]*$/ =~ s

      token(Token::Type::INTEGER, parse_int(munch_underscores(s), 2))
    end

    private def parse_int(s : String, base : Int)
      s.to_i64(base)
    rescue ArgumentError
      s.to_big_i(base)
    end

    private def munch_underscores(s)
      s.gsub(/_+/, "")
    end

    private def unescape_ws(string)
      string.gsub(/\\(\\|\s+)/) do |m|
        case m
        when "\\\\" then "\\\\"
        else             ""
        end
      end
    end

    UNESCAPE        = /\\(?:[#{WHITESPACE.join}#{NEWLINES.join}\r]+|[^u])/
    UNESCAPE_NON_WS = /\\(?:[^u])/

    private def unescape_non_ws(string)
      unescape(string, UNESCAPE_NON_WS)
    end

    private def unescape(string, rgx = UNESCAPE)
      string
        .gsub(rgx) { |m| replace_esc(m) }
        .gsub(/\\u\{[0-9a-fA-F]+\}/) do |m|
          digits = m[3..-2]
          raise_error "Invalid code point #{digits}" if digits.size > 6
          i = Int64.new(digits, 16)
          if i < 0 || i > 0x10FFFF
            raise_error "Invalid code point #{i}"
          end
          i.chr
        end
    end

    private def replace_esc(m)
      case m
      when "\\n"                                     then "\n"
      when "\\r"                                     then "\r"
      when "\\t"                                     then "\t"
      when "\\\\"                                    then "\\"
      when "\\\""                                    then "\""
      when "\\b"                                     then "\b"
      when "\\f"                                     then "\f"
      when "\\s"                                     then " "
      when /\\[#{WHITESPACE.join}#{NEWLINES.join}]+/ then ""
      else                                                raise_error "Unexpected escape #{m.inspect}"
      end
    end

    private def dedent(string)
      split = string.split(NEWLINES_PATTERN)
      return "" if split.empty?

      lines = split.each_slice(2).map(&.first).to_a
      if NEWLINES_PATTERN === split.last
        indent = ""
      else
        *lines, indent = lines
      end
      return "" if lines.empty?
      raise_error "Invalid multiline string final line" unless WS_STAR === indent
      valid = /\A#{Regex.escape(indent)}(.*)/

      lines.map do |line|
        case line
        when WS_STAR then ""
        when valid   then $1
        else              raise_error "Invalid multiline string indentation"
        end
      end.join("\n")
    end

    private def debom(str)
      return str unless str.starts_with?("\uFEFF")

      str[1..]
    end
  end
end
