require "./tokenizer"
require "./document"
require "./node"
require "./value"

module KDL
  class Parser
    def initialize
    end

    def parse(str : ::String)
      Document.new([] of Node)
    end
  end
end