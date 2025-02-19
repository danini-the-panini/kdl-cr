require "../spec_helper"

describe KDL::Node do
  describe "#[]" do
    it "returns the argument or property" do
      node = KDL::Node.new("node", arguments: [KDL::Value.new(1), KDL::Value.new("two")], properties: {"three" => KDL::Value.new(3), "four" => KDL::Value.new(4)})

      node[0].should eq 1
      node[1].should eq "two"

      node["three"].should eq 3
      node[:three].should eq 3
      node[:four].should eq 4

      expect_raises(IndexError) { node[2] }
      expect_raises(KeyError) { node["five"] }
      expect_raises(KeyError) { node[:five] }
    end
  end

  describe "#[]?" do
    it "returns the argument or property" do
      node = KDL::Node.new("node", arguments: [KDL::Value.new(1), KDL::Value.new("two")], properties: {"three" => KDL::Value.new(3), "four" => KDL::Value.new(4)})

      node[0]?.should eq 1
      node[1]?.should eq "two"

      node["three"]?.should eq 3
      node[:three]?.should eq 3
      node[:four]?.should eq 4

      node[2]?.should be_nil
      node["five"]?.should be_nil
      node[:five]?.should be_nil
    end
  end

  describe "#child" do
    it "returns the matching child node" do
      node = KDL::Node.new("node", children: [
        KDL::Node.new("foo"),
        KDL::Node.new("bar"),
      ])

      node.child(0).should eq node.children[0]
      node.child(1).should eq node.children[1]

      node.child("foo").should eq node.children[0]
      node.child(:foo).should eq node.children[0]
      node.child(:bar).should eq node.children[1]

      expect_raises(IndexError) { node.child(2) }
      expect_raises(Enumerable::NotFoundError) { node.child("baz") }
      expect_raises(Enumerable::NotFoundError) { node.child(:baz) }
    end
  end

  describe "#child?" do
    it "returns the matching child node" do
      node = KDL::Node.new("node", children: [
        KDL::Node.new("foo"),
        KDL::Node.new("bar"),
      ])

      node.child?(0).should eq node.children[0]
      node.child?(1).should eq node.children[1]

      node.child?("foo").should eq node.children[0]
      node.child?(:foo).should eq node.children[0]
      node.child?(:bar).should eq node.children[1]

      node.child?(2).should be_nil
      node.child?("baz").should be_nil
      node.child?(:baz).should be_nil
    end
  end

  describe "#arg" do
    it "returns the first arg of the matched child" do
      node = KDL::Node.new("node", children: [
        KDL::Node.new("foo", arguments: [KDL::Value.new("bar")]),
        KDL::Node.new("baz", arguments: [KDL::Value.new("qux")]),
        KDL::Node.new("norf"),
      ])

      node.arg(0).should eq "bar"
      node.arg("foo").should eq "bar"
      node.arg(:foo).should eq "bar"
      node.arg(1).should eq "qux"
      node.arg(:baz).should eq "qux"

      expect_raises(Enumerable::EmptyError) { node.arg(2) }
      expect_raises(Enumerable::EmptyError) { node.arg(:norf) }
      expect_raises(Enumerable::EmptyError) { node.arg("norf") }
      expect_raises(IndexError) { node.arg(3) }
      expect_raises(Enumerable::NotFoundError) { node.arg(:wat) }
      expect_raises(Enumerable::NotFoundError) { node.arg("wat") }
    end
  end

  describe "#arg?" do
    it "returns the first arg of the matched child" do
      node = KDL::Node.new("node", children: [
        KDL::Node.new("foo", arguments: [KDL::Value.new("bar")]),
        KDL::Node.new("baz", arguments: [KDL::Value.new("qux")]),
        KDL::Node.new("norf"),
      ])

      node.arg?(0).should eq "bar"
      node.arg?("foo").should eq "bar"
      node.arg?(:foo).should eq "bar"
      node.arg?(1).should eq "qux"
      node.arg?(:baz).should eq "qux"

      node.arg?(2).should be_nil
      node.arg?(:norf).should be_nil
      node.arg?("norf").should be_nil
      node.arg?(3).should be_nil
      node.arg?(:norf).should be_nil
      node.arg?("norf").should be_nil
    end
  end

  describe "#args" do
    it "returns the args of the matched child" do
      node = KDL::Node.new("node", children: [
        KDL::Node.new("foo", arguments: [KDL::Value.new("bar"), KDL::Value.new("baz")]),
        KDL::Node.new("qux", arguments: [KDL::Value.new("norf")]),
      ])

      node.args(0).should eq ["bar", "baz"]
      node.args("foo").should eq ["bar", "baz"]
      node.args(:foo).should eq ["bar", "baz"]
      node.args(1).should eq ["norf"]
      node.args(:qux).should eq ["norf"]

      expect_raises(IndexError) { node.args(2) }
      expect_raises(Enumerable::NotFoundError) { node.args("wat") }
      expect_raises(Enumerable::NotFoundError) { node.args(:wat) }
    end
  end

  describe "#args?" do
    it "returns the args of the matched child" do
      node = KDL::Node.new("node", children: [
        KDL::Node.new("foo", arguments: [KDL::Value.new("bar"), KDL::Value.new("baz")]),
        KDL::Node.new("qux", arguments: [KDL::Value.new("norf")]),
      ])

      node.args?(0).should eq ["bar", "baz"]
      node.args?("foo").should eq ["bar", "baz"]
      node.args?(:foo).should eq ["bar", "baz"]
      node.args?(1).should eq ["norf"]
      node.args?(:qux).should eq ["norf"]

      node.args?(2).should be_nil
      node.args?("wat").should be_nil
      node.args?(:wat).should be_nil
    end
  end

  describe "#dash_vals" do
    it "returns first argument of dash nodes" do
      node = KDL::Node.new("node", children: [
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

      node.dash_vals(0).should eq %w[foo bar baz]
      node.dash_vals("foo").should eq %w[foo bar baz]
      node.dash_vals(:foo).should eq %w[foo bar baz]

      expect_raises(Enumerable::EmptyError) { node.dash_vals(1) }
      expect_raises(Enumerable::EmptyError) { node.dash_vals("bar") }
      expect_raises(Enumerable::EmptyError) { node.dash_vals(:bar) }
      expect_raises(IndexError) { node.dash_vals(2) }
      expect_raises(Enumerable::NotFoundError) { node.dash_vals("baz") }
      expect_raises(Enumerable::NotFoundError) { node.dash_vals(:baz) }
    end
  end

  describe "#dash_vals?" do
    it "returns first argument of dash nodes" do
      node = KDL::Node.new("node", children: [
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

      node.dash_vals?(0).should eq %w[foo bar baz]
      node.dash_vals?("foo").should eq %w[foo bar baz]
      node.dash_vals?(:foo).should eq %w[foo bar baz]

      node.dash_vals?(1).should eq ["foo", nil]
      node.dash_vals?("bar").should eq ["foo", nil]
      node.dash_vals?(:bar).should eq ["foo", nil]
      node.dash_vals?(2).should be_nil
      node.dash_vals?("baz").should be_nil
      node.dash_vals?(:baz).should be_nil
    end
  end

  describe "#to_s" do
    it "returns stringified props and args" do
      node = KDL::Node.new("foo", arguments: [KDL::Value.new(1), KDL::Value.new("two")], properties: {"three" => KDL::Value.new(3)})

      node.to_s.should eq "foo 1 two three=3"
    end

    it "returns stringified children" do
      node = KDL::Node.new("a1", arguments: [KDL::Value.new("a"), KDL::Value.new(1)], properties: {"a" => KDL::Value.new(1)}, children: [
        KDL::Node.new("b1", arguments: [KDL::Value.new("b"), KDL::Value.new(1, type: "foo")], children: [
          KDL::Node.new("c1", arguments: [KDL::Value.new("c"), KDL::Value.new(1)]),
        ]),
        KDL::Node.new("b2", arguments: [KDL::Value.new("b")], properties: {"c" => KDL::Value.new(2, type: "bar")}, children: [
          KDL::Node.new("c2", arguments: [KDL::Value.new("c"), KDL::Value.new(2)]),
        ]),
        KDL::Node.new("b3", children: [] of KDL::Node, type: "baz"),
      ])

      node.to_s.should eq <<-KDL
      a1 a 1 a=1 {
          b1 b (foo)1 {
              c1 c 1
          }
          b2 b c=(bar)2 {
              c2 c 2
          }
          (baz)b3
      }
      KDL
    end

    it "stringifies comments if present" do
      node = KDL::Node.new("foo", comment: "This is a comment\nLorem ipsum dolor sit amet")

      node.to_s.should eq <<-KDL
      // This is a comment
      // Lorem ipsum dolor sit amet
      foo
      KDL
    end

    it "stringifies arg and prop comments if present" do
      node = KDL::Node.new("a1",
        arguments: [KDL::Value.new("a", comment: "This is an arg"), KDL::Value.new(1, comment: "Another arg")],
        properties: {"a" => KDL::Value.new(1, comment: "This is a prop")},
        children: [KDL::Node.new("b1", comment: "This is a child node")],
        comment: "This is a node"
      )

      node.to_s.should eq <<-KDL
      // This is a node
      a1 /* This is an arg */ a /* Another arg */ 1 /* This is a prop */ a=1 {
          // This is a child node
          b1
      }
      KDL
    end
  end
end
