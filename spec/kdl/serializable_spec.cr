require "../spec_helper"

class TestChild
  include KDL::Serializable

  @[KDL::Argument]
  property value : String
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

  @[KDL::Child(unwrap: "dash_vals")]
  property dashies : Array(String)

  @[KDL::Child]
  property norf : TestChild

  @[KDL::Children(name: "thing")]
  property things : Array(TestChild)

  @[KDL::Child(unwrap: "children")]
  property thangs : Array(TestChild)
end

describe KDL::Serializable do
  it "serializes documents" do
    doc = KDL.parse <<-KDL
    TestNode "arg1" #true 1 22 333 foo="a" bardle="b" baz="c" qux="d" {
      arg "arg2"
      args "x" "y" "z"
      props a="x" b="y" c="z"
      dashies {
        - "Lorem"
        - "Ipsum"
      }
      norf "wat"
      thing "foo"
      thing "bar"
      thing "baz"
      thangs {
        - "qux"
        - "norf"
      }
    }
    KDL

    obj = TestNode.from_kdl(doc.nodes[0])
    obj.first.should eq "arg1"
    obj.second.should eq true
    obj.numbers.should eq [1, 22, 333]
    obj.foo.should eq "a"
    obj.bar.should eq "b"
    obj.map.should eq({ "baz" => "c", "qux" => "d" })
    obj.arg.should eq "arg2"
    obj.args.should eq ["x", "y", "z"]
    obj.props.should eq({ "a" => "x", "b" => "y", "c" => "z" })
    obj.dashies.should eq(["Lorem", "Ipsum"])
    obj.norf.value.should eq "wat"
    obj.things.size.should eq 3
    obj.things[0].value.should eq "foo"
    obj.things[1].value.should eq "bar"
    obj.things[2].value.should eq "baz"
    obj.thangs.size.should eq 2
    obj.thangs[0].value.should eq "qux"
    obj.thangs[1].value.should eq "norf"

    KDL::Document.new([obj.to_kdl]).should eq doc
  end
end
