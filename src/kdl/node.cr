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
  end
end