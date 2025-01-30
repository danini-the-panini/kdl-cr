require "./kdl/*"

module KDL
  VERSION = "0.2.0"

  def self.parse(string : String)
    Parser.new.parse(string)
  end

  def self.load_file(file : IO | String)
    case file
    when String then parse(File.read(file))
    else parse(file.read)
    end
  end

  def self.build(*, comment : String? = nil, &)
    builder = Builder.new
    builder.document(comment: comment) do
      yield builder
    end
  end
end
