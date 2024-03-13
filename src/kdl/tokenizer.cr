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
      NONE
    end

    property type : Type
    property value : KDL::Value::Type
    property line : Int32
    property column : Int32
    property meta : Hash(Symbol, String)

    def initialize(@type, @value, @line = 1, @column = 1, @meta = {} of Symbol => String)
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

    EQUALS = ['=', '﹦', '＝', '🟰']

    SYMBOLS = {
      '{' => Token::Type::LBRACE,
      '}' => Token::Type::RBRACE,
      ';' => Token::Type::SEMICOLON
    }.merge(EQUALS.map { |e| { e, Token::Type::EQUALS } }.to_h)

    WHITESPACE = [
      '\u0009', '\u000B', '\u0020', '\u00A0',
      '\u1680', '\u2000', '\u2001', '\u2002',
      '\u2003', '\u2004', '\u2005', '\u2006',
      '\u2007', '\u2008', '\u2009', '\u200A',
      '\u202F', '\u205F', '\u3000' 
    ]

    NEWLINES = ['\u000A', '\u0085', '\u000C', '\u2028', '\u2029']

    NON_IDENTIFIER_CHARS = Regex.escape("#{SYMBOLS.keys.join("")}()[]/\\\"# ")
    IDENTIFER_CHARS = /[^#{NON_IDENTIFIER_CHARS}\0-\x20]/
    INITIAL_IDENTIFIER_CHARS = /[^#{NON_IDENTIFIER_CHARS}0-9\x0-\x20]/

    FORBIDDEN = [
      *'\u0000'..'\u0008',
      *'\u000E'..'\u001F',
      '\u007F',
      *'\u200E'..'\u200F',
      *'\u202A'..'\u202E',
      *'\u2066'..'\u2069',
      '\uFEFF'
    ]

    ALLOWED_IN_TYPE = [Context::Ident, Context::String, Context::Rawstring, Context::MultiLineComment, Context::Whitespace]
    NOT_ALLOWED_AFTER_TYPE = [Context::SingleLineComment]

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
            if self[@index + 1] == '\n'
              self.context = Context::MultiLineString
              traverse 2
            else
              self.context = Context::String
              traverse 1
            end
          when '#'
            case self[@index + 1]
            when '"'
              @rawstring_hashes = 1
              @buffer = ""
              if self[@index + 2] == '\n'
                self.context = Context::MultiLineRawstring
                traverse 3
              else
                self.context = Context::Rawstring
                traverse 2
              end
              next
            when '#'
              i = @index + 1
              @rawstring_hashes = 1
              while self[i] == '#'
                @rawstring_hashes += 1
                i += 1
              end
              if self[i] == '"'
                @buffer = ""
                if self[i + 1] == "\n"
                  self.context = Context::MultiLineRawstring
                  @index = i + 2
                else
                  self.context = Context::Rawstring
                  @index = i + 1
                end
                next
              end
            end
            self.context = Context::Keyword
            @buffer = c.to_s
            traverse 1
          when '-', '+'
            n = self[@index + 1]
            self.context = if !n.nil? && ('0'..'9').includes?(n)
              Context::Decimal
            else
              Context::Ident
            end
            @buffer = c.to_s
            traverse 1
          when ->(c : Char?) { /[0-9]/ === c.to_s }
            n = self[@index + 1]
            if c == '0' && n.to_s =~ /[box]/
              traverse 2
              @buffer = ""
              self.context = case n
              when 'b' then Context::Binary
              when 'o' then Context::Octal
              when 'x' then Context::Hexadecimal
              end
            else
              self.context = Context::Decimal
              @buffer = c.to_s
              traverse 1
            end
          when '\\'
            t = Tokenizer.new(@str, @index + 1)
            la = t.next_token
            if la && (la.type == Token::Type::NEWLINE || la.type == Token::Type::EOF || (la.type == Token::Type::WS && (lan = t.next_token) && (lan.type == Token::Type::NEWLINE || lan.type == Token::Type::EOF)))
              @index = t.index
              new_line
              @buffer = "#{c}#{la.value}"
              @buffer += "\n" if lan && lan.type == Token::Type::NEWLINE
              self.context = Context::Whitespace
            else
              raise_error "Unexpected '\\' (#{la ? la.type : "?"})"
            end
          when ->(c : Char?) { EQUALS.includes?(c) }
            self.context = Context::Equals
            @buffer = c.to_s
            traverse 1
          when ->(c : Char?) { SYMBOLS.has_key?(c) }
            return token(SYMBOLS[c], c.to_s).tap { traverse 1 }
          when '\r'
            n = self[@index + 1]
            token = if n == "\n"
              token(Token::Type::NEWLINE, "#{c}#{n}").tap { traverse 2 }
            else
              token(Token::Type::NEWLINE, c.to_s).tap { traverse 1 }
            end
            new_line
            return token
          when ->(c : Char?) { NEWLINES.includes?(c) }
            return token(Token::Type::NEWLINE, c.to_s).tap do
              traverse 1
              new_line
            end
          when '/'
            case self[@index + 1]
            when '/'
              self.context = Context::SingleLineComment
              traverse 2
            when '*'
              self.context = Context::MultiLineComment
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
          when ->(c: Char?) { INITIAL_IDENTIFIER_CHARS === c.to_s }
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
            return token(Token::Type::NONE, "") if done?

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
            else raise_error "Unknown keyword #{@buffer}"
            end
          end
        when Context::String, Context::MultiLineString
          case c
          when '\\'
            @buffer += c.to_s
            @buffer += self[@index + 1] || ""
            traverse 2
          when '"'
            string = convert_escapes(@buffer)
            string = @context == Context::MultiLineString ? unindent(string) : string
            return token(Token::Type::STRING, string).tap { traverse 1 }
          when nil
            raise_error "Unterminated string literal"
          else
            @buffer += c.to_s
            traverse 1
          end
        when Context::Rawstring, Context::MultiLineRawstring
          raise_error "Unterminated rawstring literal" if c.nil?

          if c == '"'
            h = 0
            while self[@index + 1 + h] == '#' && h < @rawstring_hashes
              h += 1
            end
            if h == @rawstring_hashes
              string = @context == Context::MultiLineRawstring ? unindent(@buffer) : @buffer
              return token(Token::Type::RAWSTRING, string).tap { traverse 1 + h }
            end
          end

          @buffer += c
          traverse 1
        when Context::Decimal
          case c.to_s
          when /[0-9.\-+_eE]/
            traverse 1
            @buffer += c.to_s
          else
            if c.nil? || WHITESPACE.includes?(c) || NEWLINES.includes?(c)
              return parse_decimal(@buffer)
            else
              raise_error "Unexpected '#{c}'"
            end
          end
        when Context::Hexadecimal
          if !c.nil? && !WHITESPACE.includes?(c) && !NEWLINES.includes?(c)
            traverse 1
            @buffer += c.to_s
          else
            return parse_hexadecimal(@buffer)
          end
        when Context::Octal
          if !c.nil? && !WHITESPACE.includes?(c) && !NEWLINES.includes?(c)
            traverse 1
            @buffer += c.to_s
          else
            return parse_octal(@buffer)
          end
        when Context::Binary
          if !c.nil? && !WHITESPACE.includes?(c) && !NEWLINES.includes?(c)
            traverse 1
            @buffer += c.to_s
          else
            return parse_binary(@buffer)
          end
        when Context::SingleLineComment
          if NEWLINES.includes?(c) || c == '\r'
            self.context = nil
            @column_at_start = @column
            next
          elsif c.nil?
            @done = true
            return token(Token::Type::EOF, "")
          else
            traverse 1
          end
        when Context::MultiLineComment
          if c == '/' && self[@index + 1] == '*'
            @comment_nesting += 1
            traverse 2
          elsif c == '*' && self[@index + 1] == '/'
            @comment_nesting -= 1
            traverse 2
            revert_context if @comment_nesting == 0
          else
            traverse 1
          end
        when Context::Whitespace
          if WHITESPACE.includes?(c)
            traverse 1
            @buffer += c.to_s
          elsif EQUALS.includes?(c)
            self.context = Context::Equals
            @buffer += c.to_s
            traverse 1
          elsif c == '/' && self[@index + 1] == '*'
            self.context = Context::MultiLineComment
            @comment_nesting = 1
            traverse 2
          elsif c == '\\'
            t = Tokenizer.new(@str, @index + 1)
            la = t.next_token
            if la && (la.type == Token::Type::NEWLINE || la.type == Token::Type::EOF || (la.type == Token::Type::WS && (lan = t.next_token) && (lan.type == Token::Type::NEWLINE || lan == Token::Type::EOF)))
              @index = t.index
              new_line
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
            @index = t.index
          end
          return token(Token::Type::EQUALS, @buffer)
        end
      end
    end

    private def token(type, value, meta = {} of Symbol => String)
      token = Token.new(type, value, @line_at_start, @column_at_start, meta)
      @last_token = token unless type == Token::Type::NONE
      token
    end

    private def traverse(n = 1)
      @column += n
      @index += n
    end

    private def raise_error(message)
      raise Error.new(message, @line, @column)
    end

    private def new_line
      @column = 1
      @line += 1
    end

    private def context=(val)
      if @type_context && !ALLOWED_IN_TYPE.includes?(val)
        raise_error "#{val} context not allowed in type declaration"
      elsif @last_token == Token::Type::RPAREN && NOT_ALLOWED_AFTER_TYPE.includes?(val)
        raise_error "#{val} context is not allowed after a type declaration"
      end
      @previous_context = @context
      @context = val
    end

    private def revert_context
      @context = @previous_context
      @previous_context = nil
    end

    private def parse_decimal(s)
      return parse_float(s) if s =~ /[.E]/i

      token(Token::Type::INTEGER, Int64.new(munch_underscores(s), 10), { :format => "%d" })
    rescue e
      if s[0] =~ INITIAL_IDENTIFIER_CHARS && s[1..-1].each_char.all? { |c| c =~ IDENTIFER_CHARS }
        token(Token::Type::IDENT, s)
      else
        raise e
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
        token(Token::Type::FLOAT, value, { :format => scientific ? "%.#{decimals}E" : nil }.compact)
      end
    end

    private def try_parse_float(s)
      Float64.new(s)
    rescue ArgumentError
      nil
    end

    private def parse_hexadecimal(s)
      raise_error "Invalid hexadecimal value #{s}" unless /^[a-zA-Z0-9][a-zA-Z0-9_]*$/ =~ s

      token(Token::Type::INTEGER, parse_int(munch_underscores(s), 16))
    end

    private def parse_octal(s)
      raise_error "Invalid octal value #{s}" unless /^[0-7][0-7_]*$/ =~ s
 
      token(Token::Type::INTEGER, parse_int(munch_underscores(s), 8))
    end

    private def parse_binary(s)
      raise_error "Invalid binary value #{s}" unless /^[01][01_]*$/ =~ s

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

    private def convert_escapes(string)
      string.gsub(/\\(\s+|[^u])/) do |m|
        case m
        when "\\n"    then "\n"
        when "\\r"    then "\r"
        when "\\t"    then "\t"
        when "\\\\"   then "\\"
        when "\\\""   then "\""
        when "\\b"    then "\b"
        when "\\f"    then "\f"
        when "\\s"    then ' '
        when /\\\s+/ then ""
        else raise_error "Unexpected escape #{m.inspect}"
        end
      end.gsub(/\\u\{[0-9a-fA-F]{0,6}\}/) do |m|
        i = Int64.new(m[3..-2], 16)
        if i < 0 || i > 0x10FFFF
          raise_error "Invalid code point #{i}"
        end
        i.chr
      end
    end

    private def unindent(string)
      lines = string.split("\n")
      if lines.last.ends_with?("\n")
        indent = ""
      else
        *lines, indent = lines
      end

      unless indent.empty?
        if indent.each_char.any? { |c| !WHITESPACE.includes?(c) }
          raise_error "Invalid MultiLine string final line"
        end
        if lines.any? { |line| !line.starts_with?(indent) }
          raise_error "Invalid MultiLine string indentation"
        end
      end

      lines[lines.size - 1] = lines.last.chomp
      lines.map { |line| line.gsub(/\A#{indent}/, "") }.join("\n")
    end

    private def debom(str)
      return str unless str.starts_with?("\uFEFF")

      str[1..]
    end
  end
end