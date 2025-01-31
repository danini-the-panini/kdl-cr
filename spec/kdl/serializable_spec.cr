require "../spec_helper"

class TestChild
  include KDL::Serializable

  @[KDL::Argument]
  property value : String

  def initialize(@value)
  end
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

  @[KDL::Child]
  property norf : TestChild

  @[KDL::Children(name: "thing")]
  property things : Array(TestChild)
 
  def initialize(@first, @second, @numbers, @foo, @bar, @map, @arg, @args, @props, @norf, @things)
  end
end

class TestDocument
  include KDL::Serializable

  @[KDL::Child]
  property node : TestNode

  def initialize(@node)
  end
end

describe KDL::Serializable do
  it "serializes documents" do
    doc = KDL.parse <<-KDL
    node "arg1" #true 1 22 33 foo="a" bardle="b" baz="c" qux="d" {
      arg "arg2"
      args "x" "y" "z"
      props a="x" b="y" c="z"
      norf "wat"
      thing "foo"
      thing "bar"
      thing "baz"
    }
    KDL

    obj = TestDocument.from_kdl(doc)
    obj.node.first.should eq "arg1"
    obj.node.second.should eq true
    obj.node.numbers.should eq [1, 22, 333]
    obj.node.foo.should eq "a"
    obj.node.bar.should eq "b"
    obj.node.map.should eq({ "baz": "c", "qux": "d" })
    obj.node.arg.should eq "arg2"
    obj.node.args.should eq ["x", "y", "z"]
    obj.node.props.should eq({ "a": "x", "b": "y", "c": "z" })
    obj.node.norf.value.should eq "wat"
    obj.node.things.size.should eq 3
    obj.node.things[0].value.should eq "foo"
    obj.node.things[1].value.should eq "bar"
    obj.node.things[2].value.should eq "baz"

    obj.to_kdl.should eq doc
  end
end
