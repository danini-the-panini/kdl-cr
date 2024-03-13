require "../spec_helper"

describe KDL::Document do
  describe "#to_s" do
    doc = KDL::Document.new([
      KDL::Node.new("b1", arguments: [KDL::Value.new("b"), KDL::Value.new(1i64, type: "foo")], properties: {} of String => KDL::Value, children: [
        KDL::Node.new("c1", arguments: [KDL::Value.new("c"), KDL::Value.new(1i64)])
      ]),
      KDL::Node.new("b2", arguments: [KDL::Value.new("b")], properties: { "c" => KDL::Value.new(2i64, type: "bar") }, children: [
        KDL::Node.new("c2", arguments: [KDL::Value.new("c"), KDL::Value.new(2i64)])
      ]),
      KDL::Node.new("b3", arguments: [] of KDL::Value, properties: {} of String => KDL::Value, children: [] of KDL::Node, type: "baz"),
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