module KDL
  class Node
    property name
    property arguments
    property properties
    property children
    property type
    property comment

    def initialize(
      @name : String,
      *,
      @arguments = [] of KDL::Value,
      @properties = {} of String => KDL::Value,
      @children : KDL::Document = KDL::Document.new,
      @type : String? = nil,
      @comment : String? = nil,
    )
    end

    def [](index : Int) : Value::Type
      arguments[index].value
    end

    def [](key : String) : Value::Type
      properties[key].value
    end

    def [](key : Symbol) : Value::Type
      self[key.to_s]
    end

    def []?(index : Int) : Value::Type?
      if v = arguments[index]?
        v.value
      else
        nil
      end
    end

    def []?(key : String) : Value::Type?
      if v = properties[key]?
        v.value
      else
        nil
      end
    end

    def []?(key : Symbol) : Value::Type?
      self[key.to_s]?
    end

    def child(index : Int) : Node
      children[index]
    end

    def child(key : String) : Node
      children.find! { |n| n.name == key }
    end

    def child(key : Symbol) : Node
      child(key.to_s)
    end

    def child?(index : Int) : Node?
      children[index]?
    end

    def child?(key : String) : Node?
      children.find { |n| n.name == key }
    end

    def child?(key : Symbol) : Node?
      child?(key.to_s)
    end

    def children?
      !children.empty?
    end

    def arg : Value::Type
      arguments.first.value
    end

    def arg(key) : Value::Type
      child(key).arg
    end

    def arg? : Value::Type?
      if a = arguments.first?
        a.value
      else
        nil
      end
    end

    def arg?(key) : Value::Type?
      if n = child?(key)
        n.arg?
      else
        nil
      end
    end

    def args : Array(Value::Type)
      arguments.map(&.value)
    end

    def args(key) : Array(Value::Type)
      child(key).args
    end

    def args?(key) : Array(Value::Type)?
      if n = child?(key)
        n.args
      else
        nil
      end
    end

    def dash_nodes
      children.select { |n| n.name == "-" }
    end

    def dash_vals : Array(Value::Type)
      dash_nodes.map(&.arg)
    end

    def dash_vals? : Array(Value::Type?)
      dash_nodes.map(&.arg?)
    end

    def dash_vals(key) : Array(Value::Type)
      child(key).dash_vals
    end

    def dash_vals?(key) : Array(Value::Type)?
      if n = child?(key)
        n.dash_vals?
      end
    end

    def as_type(type)
      self.type = type
      self
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
      s = ""
      if c = @comment
        s += c.lines.map { |l| "#{indent}// #{l}\n" }.join("")
      end
      t = type
      s += "#{indent}#{t.nil? ? "" : "(#{id_to_s t})"}#{id_to_s name}"
      unless arguments.empty?
        s += " #{arguments.map { |v|
                   vs = ""
                   vs += "/* #{c} */ " if c = v.comment
                   vs + v.to_s
                 }.join(" ")}"
      end
      unless properties.empty?
        s += " #{properties.map { |k, v|
                   vs = ""
                   vs += "/* #{c} */ " if c = v.comment
                   vs + "#{id_to_s k}=#{v}"
                 }.join(" ")}"
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
