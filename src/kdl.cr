require "./kdl/*"

module KDL
  VERSION = "0.1.0"

  def self.parse_document(string : String)
    Parser.new.parse(string)
  end
end
