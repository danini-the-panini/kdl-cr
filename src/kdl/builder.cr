require "./document"

module KDL
  class Builder
    class Error < Exception
    end

    private getter document

    def initialize
      @nesting = [] of KDL::Node
      @document = KDL::Document.new
    end

    def document(*, comment : String? = nil, &)
      @document.comment = comment
      yield
      @document
    end

    def node(name : String, *, type : String? = nil, comment : String? = nil, &)
      node = KDL::Node.new(name, type: type, comment: comment)
      @nesting << node
      yield
      @nesting.pop
      if parent = current_node
        parent.children << node
      else
        document.nodes << node
      end
    end

    def node(name : String, *arguments, type : String? = nil, comment : String? = nil)
      node name, type: type, comment: comment do
        arguments.each &->arg(KDL::Value::Type)
      end
    end

    # Bug: https://github.com/crystal-lang/crystal/issues/15484, separate overload needed for double splat
    def node(name : String, *arguments, type : String? = nil, comment : String? = nil, **properties)
      node name, type: type, comment: comment do
        arguments.each &->arg(KDL::Value::Type)
        properties.each &->prop(Symbol, KDL::Value::Type)
      end
    end

    def arg(value : KDL::Value::Type, *, type : String? = nil, comment : String? = nil)
      if node = current_node
        node.arguments << KDL::Value.new(value, type: type, comment: comment)
      else
        raise Error.new "Can't do argument, not inside Node"
      end
    end

    def prop(key : String | Symbol, value : KDL::Value::Type, *, type : String? = nil, comment : String? = nil)
      key = key.to_s
      if node = current_node
        node.properties[key] = KDL::Value.new(value, type: type, comment: comment)
      else
        raise Error.new "Can't do property, not inside Node"
      end
    end

    private def current_node
      return nil if @nesting.empty?

      @nesting.last
    end
  end
end
