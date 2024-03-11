require "./node"

module KDL
  class Document
    property children

    def initialize(@children = [] of Node)
    end

    def ==(other : KDL::Document)
      children == other.children
    end

    def ==(other)
      children == other
    end

    def_hash children
  end
end