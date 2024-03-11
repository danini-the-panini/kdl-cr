require "big"

module KDL
  class Value
    alias Type = Nil | Bool | Int64 | Float64 | BigDecimal | String

    # Returns the raw underlying value.
    property value : Type
    property type : String?

    def initialize(@value : Type, *, @type : String? = nil)
    end

    def as_type(type : String?)
      self.class.new(@value, type: type)
    end

    # Checks that the underlying value is `Nil`, and returns `nil`.
    # Raises otherwise.
    def as_nil : Nil
      @value.as(Nil)
    end

    # Checks that the underlying value is `Bool`, and returns its value.
    # Raises otherwise.
    def as_bool : Bool
      @value.as(Bool)
    end

    # Checks that the underlying value is `Bool`, and returns its value.
    # Returns `nil` otherwise.
    def as_bool? : Bool?
      as_bool if @value.is_a?(Bool)
    end

    # Checks that the underlying value is `Int`, and returns its value as an `Int32`.
    # Raises otherwise.
    def as_i : Int32
      @value.as(Int).to_i
    end

    # Checks that the underlying value is `Int`, and returns its value as an `Int32`.
    # Returns `nil` otherwise.
    def as_i? : Int32?
      as_i if @value.is_a?(Int)
    end

    # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
    # Raises otherwise.
    def as_i64 : Int64
      @value.as(Int).to_i64
    end

    # Checks that the underlying value is `Int`, and returns its value as an `Int64`.
    # Returns `nil` otherwise.
    def as_i64? : Int64?
      as_i64 if @value.is_a?(Int64)
    end

    # Checks that the underlying value is `Float` (or `Int`), and returns its value as an `Float64`.
    # Raises otherwise.
    def as_f : Float64
      case value = @value
      when Int
        value.to_f
      else
        value.as(Float64)
      end
    end

    # Checks that the underlying value is `Float` (or `Int`), and returns its value as an `Float64`.
    # Returns `nil` otherwise.
    def as_f? : Float64?
      case value = @value
      when Int
        value.to_f
      else
        value.as?(Float64)
      end
    end

    # Checks that the underlying value is `Float` (or `Int`), and returns its value as an `Float32`.
    # Raises otherwise.
    def as_f32 : Float32
      case value = @value
      when Int
        value.to_f32
      else
        value.as(Float).to_f32
      end
    end

    # Checks that the underlying value is `Float` (or `Int`), and returns its value as an `Float32`.
    # Returns `nil` otherwise.
    def as_f32? : Float32?
      case value = @value
      when Int
        value.to_f32
      when Float
        value.to_f32
      else
        nil
      end
    end

    # Checks that the underlying value is `String`, and returns its value.
    # Raises otherwise.
    def as_s : String
      @value.as(String)
    end

    # Checks that the underlying value is `String`, and returns its value.
    # Returns `nil` otherwise.
    def as_s? : String?
      as_s if @value.is_a?(String)
    end

    def inspect(io : IO) : Nil
      @value.inspect(io)
    end

    def to_s(io : IO) : Nil
      @value.to_s(io)
    end

    # :nodoc:
    def pretty_print(pp)
      @value.pretty_print(pp)
    end

    # Returns `true` if both `self` and *other*'s value object are equal.
    def ==(other : KDL::Value)
      value == other.value && type == other.type
    end

    # Returns `true` if the value object is equal to *other*.
    def ==(other)
      value == other
    end

    # See `Object#hash(hasher)`
    def_hash value
  end
end

class Object
  def ===(other : KDL::Value)
    self === other.raw
  end
end

struct Value
  def ==(other : KDL::Value)
    self == other.raw
  end
end

class Reference
  def ==(other : KDL::Value)
    self == other.raw
  end
end

class Array
  def ==(other : KDL::Value)
    self == other.raw
  end
end

class Hash
  def ==(other : KDL::Value)
    self == other.raw
  end
end

class Regex
  def ===(other : KDL::Value)
    value = self === other.raw
    $~ = $~
    value
  end
end