require "big"

module KDL
  class Value(T)
    def initialize(@value : T)
    end
  end

  class String < Value(::String)
  end

  class Int < Value(Int64)
  end

  class Float < Value(Float64)
  end

  class Decimal < Value(BigDecimal)
  end

  class Bool < Value(Bool)
  end

  class NullImpl < Value(Nil)
    def initialize
      super(nil)
    end
  end
  Null = NullImple.new
end