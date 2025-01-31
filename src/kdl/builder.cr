require "./document"

module KDL
  class Builder
    class Error < Exception
    end

    private getter document

    def initialize
      @nesting = [] of Node
      @document = Document.new
    end

    def document(*, comment : String? = nil, &)
      @document.comment = comment
      yield
      @document
    end

    def node(name : String, *, type : String? = nil, comment : String? = nil, &)
      node = Node.new(name, type: type, comment: comment)
      @nesting << node
      yield
      @nesting.pop
      if parent = current_node
        parent.children << node
      else
        document << node
      end
    end

    # Node name only
    def node(name : String, *, type : String? = nil, comment : String? = nil)
      node(name, type: type, comment: comment) { }
    end

    # Name and shorthand positional arguments + properties
    def node(name : String, *positional : Value::Type | Hash(String, Value::Type), type : String? = nil, comment : String? = nil)
      node name, type: type, comment: comment do
        positional.each { |argument| positional_arg_or_prop argument }
      end
    end

    # Name and named tuple properties
    def node(name : String, *, type : String? = nil, comment : String? = nil, **properties : Value::Type)
      node name, type: type, comment: comment do
        properties.each do |key, value|
          prop key, value
        end
      end
    end

    # Name and shorthand positional arguments + properties with named tuple properties
    def node(name : String, *positional : Value::Type | Hash(String, Value::Type), type : String? = nil, comment : String? = nil, **properties : Value::Type)
      node name, type: type, comment: comment do
        positional.each { |argument| positional_arg_or_prop argument }

        properties.each do |key, value|
          prop key, value
        end
      end
    end

    def arg(value : Value::Type, *, type : String? = nil, comment : String? = nil)
      if node = current_node
        node.arguments << Value.new(value, type: type, comment: comment)
      else
        raise Error.new "Can't do argument, not inside Node"
      end
    end

    def prop(key : String | Symbol, value : Value::Type, *, type : String? = nil, comment : String? = nil)
      key = key.to_s
      if node = current_node
        node.properties[key] = Value.new(value, type: type, comment: comment)
      else
        raise Error.new "Can't do property, not inside Node"
      end
    end

    private def current_node
      return nil if @nesting.empty?

      @nesting.last
    end

    private def positional_arg_or_prop(input : Value::Type | Hash(String, Value::Type))
      case input
      in Hash
        input.each do |key, value|
          raise ArgumentError.new "Invalid hash key or value" unless key.is_a? String && value.is_a? Value::Type
          prop key, value
        end
      in Value::Type
        arg input
      end
    end
  end
end
