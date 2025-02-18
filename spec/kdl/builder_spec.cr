require "../spec_helper"

describe KDL::Builder do
  describe "KDL.build" do
    it "builds a kdl document" do
      doc = KDL.build do |kdl|
        kdl.node "foo"
        kdl.node "bar", type: "baz"
        kdl.node "qux" do
          kdl.arg 123i64
          kdl.prop "norf", "wat"
          kdl.prop "when", "2025-01-30", type: "date"
          kdl.node "child"
        end
      end

      doc.to_s.should eq <<-KDL
      foo
      (baz)bar
      qux 123 norf=wat when=(date)"2025-01-30" {
          child
      }

      KDL
    end

    it "builds kdl documents with comments" do
      doc = KDL.build(comment: "This is a document\nwith comments") do |kdl|
        kdl.node "foo", comment: "Some node"
        kdl.node "bar", type: "baz", comment: "Some other node"
        kdl.node "qux" do
          kdl.arg 123i64, comment: "an arg"
          kdl.prop "norf", "wat", comment: "a prop"
          kdl.prop "when", "2025-01-30", type: "date"
          kdl.node "child", comment: "a child node"
        end
      end

      doc.to_s.should eq <<-KDL
      // This is a document
      // with comments

      // Some node
      foo
      // Some other node
      (baz)bar
      qux /* an arg */ 123 /* a prop */ norf=wat when=(date)"2025-01-30" {
          // a child node
          child
      }

      KDL
    end

    describe "shorthand" do
      it "builds a node with a single argument" do
        doc = KDL.build do |kdl|
          kdl.node "snorlax" do
            kdl.node "size", 10_i64
          end
        end

        doc.to_s.should eq <<-KDL
        snorlax {
            size 10
        }

        KDL
      end

      it "builds a node with shorthand properties" do
        doc = KDL.build do |kdl|
          kdl.node "pokemon", properties: {"pokemon_type" => "normal", "level" => 10_i64}
        end

        doc.to_s.should eq <<-KDL
      pokemon pokemon_type=normal level=10

      KDL
      end

      it "builds a node with positional shorthand properties" do
        doc = KDL.build do |kdl|
          kdl.node "pokemon", {"Pokemon type" => "normal", "Level" => 10_i64}
        end

        doc.to_s.should eq <<-KDL
        pokemon "Pokemon type"=normal Level=10

        KDL
      end

      it "builds a node with positional properties and arguments" do
        doc = KDL.build do |kdl|
          kdl.node "pokemon", "snorlax", "jigglypuff", {"Pokemon type" => "normal", "Level" => 10_i64}
        end

        doc.to_s.should eq <<-KDL
        pokemon snorlax jigglypuff "Pokemon type"=normal Level=10

        KDL
      end

      it "builds a node with mixed order positional properties and arguments" do
        doc = KDL.build do |kdl|
          kdl.node "pokemon", "snorlax", {"Pokemon type" => "normal"}, "jigglypuff", {"Level" => 10_i64}
        end

        doc.to_s.should eq <<-KDL
        pokemon snorlax jigglypuff "Pokemon type"=normal Level=10

        KDL
      end

      it "builds a node with positional arguments, and named properties" do
        doc = KDL.build do |kdl|
          kdl.node "pokemon", "snorlax", "jigglypuff", properties: {"Trainer" => "Sylphrena"}
        end

        doc.to_s.should eq <<-KDL
        pokemon snorlax jigglypuff Trainer=Sylphrena

        KDL
      end
    end
  end
end
