require "../spec_helper"

describe KDL::Document do
  describe "#[]" do
    it "references nodes" do
      doc = KDL::Document.new([
        KDL::Node.new("foo"),
        KDL::Node.new("bar"),
      ])

      doc[0].should eq doc.nodes[0]
      doc[1].should eq doc.nodes[1]

      doc["foo"].should eq doc.nodes[0]
      doc[:foo].should eq doc.nodes[0]
      doc["bar"].should eq doc.nodes[1]

      expect_raises(IndexError) { doc[2] }
      expect_raises(Enumerable::NotFoundError) { doc["baz"] }
      expect_raises(Enumerable::NotFoundError) { doc[:baz] }
    end
  end

  describe "#[]?" do
    it "references nodes" do
      doc = KDL::Document.new([
        KDL::Node.new("foo"),
        KDL::Node.new("bar"),
      ])

      doc[0]?.should eq doc.nodes[0]
      doc[1]?.should eq doc.nodes[1]

      doc["foo"]?.should eq doc.nodes[0]
      doc[:foo]?.should eq doc.nodes[0]
      doc[:bar]?.should eq doc.nodes[1]

      doc[2]?.should be_nil
      doc["baz"]?.should be_nil
      doc[:baz]?.should be_nil
    end
  end

  describe "#arg" do
    it "fetches first argument from matching node" do
      doc = KDL::Document.new([
        KDL::Node.new("foo", arguments: [KDL::Value.new("bar")]),
        KDL::Node.new("baz", arguments: [KDL::Value.new("qux")]),
        KDL::Node.new("norf"),
      ])

      doc.arg(0).should eq "bar"
      doc.arg("foo").should eq "bar"
      doc.arg(:foo).should eq "bar"
      doc.arg(1).should eq "qux"
      doc.arg(:baz).should eq "qux"

      expect_raises(Enumerable::EmptyError) { doc.arg(2) }
      expect_raises(Enumerable::EmptyError) { doc.arg("norf") }
      expect_raises(IndexError) { doc.arg(3) }
      expect_raises(Enumerable::NotFoundError) { doc.arg(:wat) }
      expect_raises(Enumerable::NotFoundError) { doc.arg("wat") }
    end
  end

  describe "#arg?" do
    it "fetches first argument from matching node" do
      doc = KDL::Document.new([
        KDL::Node.new("foo", arguments: [KDL::Value.new("bar")]),
        KDL::Node.new("baz", arguments: [KDL::Value.new("qux")]),
        KDL::Node.new("norf"),
      ])

      doc.arg?(0).should eq "bar"
      doc.arg?("foo").should eq "bar"
      doc.arg?(:foo).should eq "bar"
      doc.arg?(1).should eq "qux"
      doc.arg?(:baz).should eq "qux"
      doc.arg?(2).should be_nil
      doc.arg?(:norf).should be_nil

      doc.arg?(3).should be_nil
      doc.arg?(:wat).should be_nil
      doc.arg?("wat").should be_nil
    end
  end

  describe "#dash_vals" do
    it "returns arguments from dash nodes" do
      doc = KDL::Document.new([
        KDL::Node.new("foo", children: [
          KDL::Node.new("-", arguments: [KDL::Value.new("foo")]),
          KDL::Node.new("-", arguments: [KDL::Value.new("bar")]),
          KDL::Node.new("-", arguments: [KDL::Value.new("baz")]),
        ]),
        KDL::Node.new("bar", children: [
          KDL::Node.new("-", arguments: [KDL::Value.new("foo")]),
          KDL::Node.new("-"),
        ]),
      ])

      doc.dash_vals(0).should eq ["foo", "bar", "baz"]
      doc.dash_vals("foo").should eq ["foo", "bar", "baz"]
      doc.dash_vals(:foo).should eq ["foo", "bar", "baz"]

      expect_raises(Enumerable::EmptyError) { doc.dash_vals(:bar) }
      expect_raises(IndexError) { doc.dash_vals(2) }
      expect_raises(Enumerable::NotFoundError) { doc.dash_vals("baz") }
      expect_raises(Enumerable::NotFoundError) { doc.dash_vals(:baz) }
    end
  end

  describe "#dash_vals?" do
    it "returns arguments from dash nodes" do
      doc = KDL::Document.new([
        KDL::Node.new("foo", children: [
          KDL::Node.new("-", arguments: [KDL::Value.new("foo")]),
          KDL::Node.new("-", arguments: [KDL::Value.new("bar")]),
          KDL::Node.new("-", arguments: [KDL::Value.new("baz")]),
        ]),
        KDL::Node.new("bar", children: [
          KDL::Node.new("-", arguments: [KDL::Value.new("foo")]),
          KDL::Node.new("-"),
        ]),
      ])

      doc.dash_vals?(0).should eq ["foo", "bar", "baz"]
      doc.dash_vals?("foo").should eq ["foo", "bar", "baz"]
      doc.dash_vals?(:foo).should eq ["foo", "bar", "baz"]
      doc.dash_vals?(:bar).should eq ["foo", nil]

      doc.dash_vals?(2).should be_nil
      doc.dash_vals?("baz").should be_nil
      doc.dash_vals?(:baz).should be_nil
    end
  end

  describe "#to_s" do
    doc = KDL::Document.new([
      KDL::Node.new("b1", arguments: [KDL::Value.new("b"), KDL::Value.new(1i64, type: "foo")], children: [
        KDL::Node.new("c1", arguments: [KDL::Value.new("c"), KDL::Value.new(1i64)]),
      ]),
      KDL::Node.new("b2", arguments: [KDL::Value.new("b")], properties: {"c" => KDL::Value.new(2i64, type: "bar")}, children: [
        KDL::Node.new("c2", arguments: [KDL::Value.new("c"), KDL::Value.new(2i64)]),
      ]),
      KDL::Node.new("b3", children: [] of KDL::Node, type: "baz"),
    ])

    doc.to_s.should eq <<-KDL
    b1 b (foo)1 {
        c1 c 1
    }
    b2 b c=(bar)2 {
        c2 c 2
    }
    (baz)b3

    KDL
  end
end
