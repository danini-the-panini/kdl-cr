require "./kdl/*"

module KDL
  VERSION = "0.2.0"

  def self.parse(string : String, *, parse_comments : Bool = false)
    parser = Parser.new(parse_comments: parse_comments)
    parser.parse(string)
  end

  def self.load_file(file : IO | String, *, parse_comments : Bool = false)
    contents = case file
               in String
                 File.read(file)
               in IO
                 file.read
               end

    parse contents, parse_comments: parse_comments
  end

  def self.build(*, comment : String? = nil, &)
    builder = Builder.new
    builder.document(comment: comment) do
      yield builder
    end
  end
end
