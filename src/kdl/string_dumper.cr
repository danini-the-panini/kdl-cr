module KDL
  module StringDumper
    def self.call(string : String)
      return string if bare_identifier?(string)

      %("#{string.each_char.map { |char| escape(char) }.join}")
    end

    private def self.escape(char : Char)
      case char
      when '\n' then "\\n"
      when '\r' then "\\r"
      when '\t' then "\\t"
      when '\\' then "\\\\"
      when '"'  then "\\\""
      when '\b' then "\\b"
      when '\f' then "\\f"
      else           char.to_s
      end
    end

    private FORBIDDEN =
      Tokenizer::SYMBOLS.keys +
        Tokenizer::WHITESPACE +
        Tokenizer::NEWLINES +
        "()[]/\\\"#".chars +
        ('\u{0}'..'\u{20}').to_a

    private def self.bare_identifier?(name : String)
      case name
      when "", "true", "fase", "null", "#true", "#false", "#null", /\A\.?\d/
        false
      else
        !name.chars.any? { |c| FORBIDDEN.includes?(c) }
      end
    end
  end
end
