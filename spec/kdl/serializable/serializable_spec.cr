require "../../spec_helper"
require "./test_classes"

class TestChild
  include KDL::Serializable

  @[KDL::Argument]
  property value : String
end

describe KDL::Serializable do
  it "serializes test node" do
    kdl = KDL.load_file "#{__DIR__}/kdl_documents/full_document.kdl"
    doc = TestDoc.from_kdl(kdl)
    obj = doc.test_node.not_nil!

    obj.should be_a TestNode
    obj.first.should eq "arg1"
    obj.second.should eq true
    obj.numbers.should eq [1, 22, 333]
    obj.foo.should eq "a"
    obj.bar.should eq "b"
    obj.map.should eq({"baz" => "c", "qux" => "d"})
    obj.arg.should eq "arg2"
    obj.args.should eq ["x", "y", "z"]
    obj.props.should eq({"a" => "x", "b" => "y", "c" => "z"})
    obj.feature_name.should eq("florp")
    obj.feature_enabled.should eq(true)
    obj.feature_option.should eq(42_u64)
    obj.dashies.should eq(["Lorem", "Ipsum"])
    obj.norf.value.should eq "wat"
    obj.things.size.should eq 3
    obj.things[0].value.should eq "foo"
    obj.things[1].value.should eq "bar"
    obj.things[2].value.should eq "baz"
    obj.thangs.size.should eq 2
    obj.thangs[0].value.should eq "qux"
    obj.thangs[1].value.should eq "norf"
    obj.paths.should eq ["some/path", "some/other/path"]
  end

  describe "missing arguments" do
    kdl = KDL.load_file "#{__DIR__}/kdl_documents/missing_argument.kdl"

    it "handles nilable, no default" do
      doc = Missing.from_kdl(kdl)

      doc.string.should eq nil
      doc.int.should eq nil
      doc.bool.should eq nil
      doc.class.should be_a TestNodeTwo # Parity with `JSON::Serializable when a key is present but is empty.`
      doc.class.not_nil!.one.should eq "Unset"
    end

    it "handles nilable, with default" do
      doc = Missing.from_kdl(kdl)

      doc.default_string.should eq "I exist!"
      doc.default_int.should eq 1234
      doc.default_bool.should eq true
      doc.default_class.should be_a TestNodeTwo
      doc.default_class.not_nil!.one.should eq "Unset" # Parity with `JSON::Serializable when a key is present but is empty.`
    end

    it "raises when not nilable, no default" do
      expect_raises(KDL::SerializableException) do
        doc = MissingWillError.from_kdl(kdl)
      end
    end
  end

  describe "missing keys" do
    kdl = KDL.parse ""

    it "handles nilable, no default" do
      doc = Missing.from_kdl(kdl)

      doc.string.should eq nil
      doc.int.should eq nil
      doc.bool.should eq nil
      doc.class.should eq nil
    end

    it "handles nilable, with default" do
      doc = Missing.from_kdl(kdl)

      doc.default_string.should eq "I exist!"
      doc.default_int.should eq 1234
      doc.default_bool.should eq true
      doc.default_class.should be_a TestNodeTwo
      doc.default_class.not_nil!.one.should eq "Set"
    end

    it "raises when not nilable, no default" do
      expect_raises(KDL::SerializableException) do
        doc = MissingWillError.from_kdl(kdl)
      end
    end
  end

  # Does not work currently, because it always wraps the entire document with the topmost class name.
  # Todo:
  pending "Deserializes the seralized data" do
    KDL::Document.new([doc.to_kdl]).should eq parsed
  end
end
