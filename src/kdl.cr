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
end
