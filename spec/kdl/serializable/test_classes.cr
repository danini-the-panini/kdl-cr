class TestDoc
  include KDL::Serializable

  @[KDL::Child(name: "TestNode")]
  property test_node : TestNode
end

# Class to simulate missing keys, arguments etc.
# Todo: properties
class Missing
  include KDL::Serializable

  @[KDL::Child(unwrap: "argument")]
  property string : String?

  @[KDL::Child(unwrap: "argument")]
  property int : Int64?

  @[KDL::Child(unwrap: "argument")]
  property bool : Bool?

  @[KDL::Child]
  property class : TestNodeTwo?

  @[KDL::Child(unwrap: "argument")]
  property default_string : String? = "I exist!"

  @[KDL::Child(unwrap: "argument")]
  property default_int : Int64? = 1234

  @[KDL::Child(unwrap: "argument")]
  property default_bool : Bool? = true

  @[KDL::Child(name: "class")]
  property default_class : TestNodeTwo? = TestNodeTwo.new(one: "Set")
end

# :ditto:
# Should raise an exception.
class MissingWillError
  include KDL::Serializable

  @[KDL::Child(unwrap: "argument")]
  property string : String

  @[KDL::Child(unwrap: "argument")]
  property int : Int64

  @[KDL::Child(unwrap: "argument")]
  property bool : Bool

  @[KDL::Child]
  property class : TestNodeTwo
end

class TestNode
  include KDL::Serializable

  @[KDL::Argument]
  property first : String

  @[KDL::Argument]
  property second : Bool

  @[KDL::Arguments]
  property numbers : Array(UInt32)

  @[KDL::Property]
  property foo : String

  @[KDL::Property(name: "bardle")]
  property bar : String

  @[KDL::Properties]
  property map : Hash(String, String)

  @[KDL::Child(unwrap: "argument")]
  property arg : String

  @[KDL::Child(unwrap: "arguments")]
  property args : Array(String)

  @[KDL::Child(unwrap: "properties")]
  property props : Hash(String, String)

  @[KDL::Child(name: "feature", unwrap: "argument")]
  property feature_name : String

  @[KDL::Child(name: "feature", unwrap: "property", property_name: "enabled")]
  property feature_enabled : Bool

  @[KDL::Child(name: "feature", unwrap: "property", property_name: "option")]
  property feature_option : UInt32

  @[KDL::Child(unwrap: "dash_vals")]
  property dashies : Array(String)

  @[KDL::Child]
  property norf : TestChild

  @[KDL::Children(name: "thing")]
  property things : Array(TestChild)

  @[KDL::Child(unwrap: "children")]
  property thangs : Array(TestChild)

  @[KDL::Children(name: "path", unwrap: "argument")]
  property paths : Array(String)
end

class TestNodeTwo
  include KDL::Serializable

  @[KDL::Child(unwrap: "argument")]
  property one : String? = "Unset"

  def initialize(@one)
  end
end
