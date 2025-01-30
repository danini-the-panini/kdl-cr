require "./node"

module KDL
  class Document
    property nodes
    property comment

    def initialize(@nodes = [] of Node, *, @comment : String? = nil)
    end

    def [](index : Int)
      nodes[index]
    end

    def [](key : String)
      nodes.find! { |n| n.name == key }
    end

    def [](key : Symbol)
      self[key.to_s]
    end

    def []?(index : Int)
      nodes[index]?
    end

    def []?(key : String)
      nodes.find { |n| n.name == key }
    end

    def []?(key : Symbol)
      self[key.to_s]?
    end

    def arg(key) : Value::Type
      self[key].arg
    end

    def arg?(key) : Value::Type?
      if n = self[key]?
        n.arg?
      else
        nil
      end
    end

    def dash_vals(key) : Array(Value::Type)
      self[key].dash_vals
    end

    def dash_vals?(key) : Array(Value::Type)?
      if n = self[key]?
        n.dash_vals?
      else
        nil
      end
    end

    def ==(other : KDL::Document)
      nodes == other.nodes
    end

    def ==(other)
      nodes == other
    end

    def_hash nodes

    def to_s(io : IO) : Nil
      if c = @comment
        io << c.lines.map { |l| "// #{l}\n" }.join("")
        io << "\n"
      end

      if @nodes.empty?
        io << "\n"
        return
      end

      @nodes.each do |node|
        node.to_s(io)
        io << "\n"
      end
    end
  end
end
