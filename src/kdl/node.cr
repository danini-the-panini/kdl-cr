module KDL
  class Node
    def initialize(@name : ::String, @arguments = [] of KDL::Value(Result), @properties = {} of String => KDL::Value(Result), @children = [] of Node)
    end
  end
end