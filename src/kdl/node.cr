module KDL
  class Node
    property name
    property arguments
    property properties
    property children
    property type

    def initialize(@name : String, *, @arguments = [] of KDL::Value, @properties = {} of String => KDL::Value, @children = [] of Node, @type : String? = nil)
    end

    def ==(other : KDL::Node)
      name == other.name &&
      arguments == other.arguments &&
      properties == other.properties &&
      children == other.children &&
      type == other.type
    end

    def ==(other)
      false
    end

    def_hash name, arguments, properties, children, type

    def to_s(io : IO)
      io << stringify
    end

    protected def stringify(level = 0) : String
      indent = "    " * level
      t = type
      s = "#{indent}#{t.nil? ? "" : "(#{id_to_s t})"}#{id_to_s name}"
      unless arguments.empty?
        s += " #{arguments.map(&.to_s).join(" ")}"
      end
      unless properties.empty?
        s += " #{properties.map { |k, v| "#{id_to_s k}=#{v}" }.join(" ")}"
      end
      unless children.empty?
        s += " {\n"
        s += children.map(&.stringify(level + 1)).join("\n")
        s += "\n#{indent}}"
      end
      s
    end

    private def id_to_s(id : String)
      StringDumper.call(id)
    end
  end
end