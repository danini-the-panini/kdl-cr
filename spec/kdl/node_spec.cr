require "../spec_helper"

describe KDL::Node do
  describe "#to_s" do
    it "returns stringified props and args" do
      node = KDL::Node.new("foo", arguments: [KDL::Value.new(1i64), KDL::Value.new("two")], properties: { "three" => KDL::Value.new(3i64) })

      node.to_s.should eq "foo 1 two three=3"
    end

    it "returns stringified children" do
      node = KDL::Node.new("a1", arguments: [KDL::Value.new("a"), KDL::Value.new(1i64)], properties: { "a" => KDL::Value.new(1i64) }, children: [
        KDL::Node.new("b1", arguments: [KDL::Value.new("b"), KDL::Value.new(1i64, type: "foo")], properties: {} of String => KDL::Value, children: [
          KDL::Node.new("c1", arguments: [KDL::Value.new("c"), KDL::Value.new(1i64)])
        ]),
        KDL::Node.new("b2", arguments: [KDL::Value.new("b")], properties: { "c" => KDL::Value.new(2i64, type: "bar") }, children: [
          KDL::Node.new("c2", arguments: [KDL::Value.new("c"), KDL::Value.new(2i64)])
        ]),
        KDL::Node.new("b3", arguments: [] of KDL::Value, properties: {} of String => KDL::Value, children: [] of KDL::Node, type: "baz"),
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
  end
end