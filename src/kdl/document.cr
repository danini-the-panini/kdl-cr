require "./node"

module KDL
  class Document
    def initialize(@children = [] of Node)
    end
  end
end