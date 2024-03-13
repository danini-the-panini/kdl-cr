require "./node"

module KDL
  class Document
    property nodes

    def initialize(@nodes = [] of Node)
    end

    def ==(other : KDL::Document)
      nodes == other.nodes
    end

    def ==(other)
      nodes == other
    end

    def_hash nodes

    def to_s(io : IO) : Nil
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