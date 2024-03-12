require "../spec_helper"

def parser
  KDL::Parser.new
end

describe KDL::Parser do
  it "parses empty string" do
    parser.parse("").should eq KDL::Document.new([] of KDL::Node)
    parser.parse(" ").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("\n").should eq KDL::Document.new([] of KDL::Node)
  end

  it "parses nodes" do
    parser.parse("node").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node\n").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("\nnode\n").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node1\nnode2").should eq(
      KDL::Document.new([
        KDL::Node.new("node1"),
        KDL::Node.new("node2")
      ])
    )
  end

  it "parses node" do
    parser.parse("node;").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node 1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1i64)] of KDL::Value)])
    parser.parse(%(node 1 2 "3" #true #false #null)).should eq KDL::Document.new([
      KDL::Node.new("node", arguments: [
        KDL::Value.new(1i64),
        KDL::Value.new(2i64),
        KDL::Value.new("3"),
        KDL::Value.new(true),
        KDL::Value.new(false),
        KDL::Value.new(nil)
      ] of KDL::Value)
    ])
    parser.parse("node {\n  node2\n}").should eq KDL::Document.new([KDL::Node.new("node", children: [KDL::Node.new("node2")])])
    parser.parse("node {\n    node2    \n}").should eq KDL::Document.new([KDL::Node.new("node", children: [KDL::Node.new("node2")])])
    parser.parse("node { node2; }").should eq KDL::Document.new([KDL::Node.new("node", children: [KDL::Node.new("node2")])])
    parser.parse("node { node2 }").should eq KDL::Document.new([KDL::Node.new("node", children: [KDL::Node.new("node2")])])
    parser.parse("node { node2; node3 }").should eq KDL::Document.new([KDL::Node.new("node", children: [KDL::Node.new("node2"), KDL::Node.new("node3")])])
  end

  it "parses node slashdash comment" do
    parser.parse("/-node").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/- node").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/- node\n").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/-node 1 2 3").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/-node key=#false").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/-node{\nnode\n}").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/-node 1 2 3 key=\"value\" \\\n{\nnode\n}").should eq KDL::Document.new([] of KDL::Node)
  end

  it "parses arg slashdash comment" do
    parser.parse("node /-1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /-1 2").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(2i64)] of KDL::Value)])
    parser.parse("node 1 /- 2 3").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1i64), KDL::Value.new(3i64)] of KDL::Value)])
    parser.parse("node /--1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /- -1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node \\\n/- -1").should eq KDL::Document.new([KDL::Node.new("node")])
  end

  it "parses prop slashdash comment" do
    parser.parse("node /-key=1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /- key=1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node key=1 /-key2=2").should eq KDL::Document.new([KDL::Node.new("node", properties: { "key" => KDL::Value.new(1i64) } of String => KDL::Value)])
  end

  it "parses children slashdash comment" do
    parser.parse("node /-{}").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /- {}").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /-{\nnode2\n}").should eq KDL::Document.new([KDL::Node.new("node")])
  end

  it "parses string" do
    parser.parse(%(node "")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("")] of KDL::Value)])
    parser.parse(%(node "hello")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("hello")] of KDL::Value)])
    parser.parse(%(node "hello\nworld")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("hello\nworld")] of KDL::Value)])
    parser.parse(%(node -flag)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("-flag")] of KDL::Value)])
    parser.parse(%(node --flagg)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("--flagg")] of KDL::Value)])
    parser.parse(%(node "\\u{10FFF}")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("\u{10FFF}")] of KDL::Value)])
    parser.parse(%(node "\\"\\\\\\b\\f\\n\\r\\t")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("\"\\\b\f\n\r\t")] of KDL::Value)])
    parser.parse(%(node "\\u{10}")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("\u{10}")] of KDL::Value)])
    expect_raises(Exception) { parser.parse(%(node "\\i")) }
    expect_raises(Exception) { parser.parse(%(node "\\u{c0ffee}")) }
  end

  it "parses unindented multiline strings" do
    parser.parse("node \"\n  foo\n  bar\n    baz\n  qux\n  \"").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("foo\nbar\n  baz\nqux")] of KDL::Value)])
    parser.parse("node #\"\n  foo\n  bar\n    baz\n  qux\n  \"#").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("foo\nbar\n  baz\nqux")] of KDL::Value)])
    expect_raises(Exception) { parser.parse("node \"\n    foo\n  bar\n    baz\n    \"") }
    expect_raises(Exception) { parser.parse("node #\"\n    foo\n  bar\n    baz\n    \"#") }
  end

  it "parses float" do
    parser.parse("node 1.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1.0)] of KDL::Value)])
    parser.parse("node 0.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(0.0)] of KDL::Value)])
    parser.parse("node -1.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(-1.0)] of KDL::Value)])
    parser.parse("node +1.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1.0)] of KDL::Value)])
    parser.parse("node 1.0e10").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1.0e10)] of KDL::Value)])
    parser.parse("node 1.0e-10").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1.0e-10)] of KDL::Value)])
    parser.parse("node 123_456_789.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(123456789.0)] of KDL::Value)])
    parser.parse("node 123_456_789.0_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(123456789.0)] of KDL::Value)])
    expect_raises(Exception) { parser.parse("node 1._0") }
    expect_raises(Exception) { parser.parse("node 1.") }
    expect_raises(Exception) { parser.parse("node 1.0v2") }
    expect_raises(Exception) { parser.parse("node -1em") }
    expect_raises(Exception) { parser.parse("node .0") }
  end

  it "parses integer" do
    parser.parse("node 0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(0i64)] of KDL::Value)])
    parser.parse("node 0123456789").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(123456789i64)] of KDL::Value)])
    parser.parse("node 0123_456_789").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(123456789i64)] of KDL::Value)])
    parser.parse("node 0123_456_789_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(123456789i64)] of KDL::Value)])
    parser.parse("node +0123456789").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(123456789i64)] of KDL::Value)])
    parser.parse("node -0123456789").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(-123456789i64)] of KDL::Value)])
  end

  it "parses hexadecimal" do
    parser.parse("node 0x0123456789abcdef").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(0x0123456789abcdef)])])
    parser.parse("node 0x01234567_89abcdef").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(0x0123456789abcdef)])])
    parser.parse("node 0x01234567_89abcdef_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(0x0123456789abcdef)])])
    expect_raises(Exception) { parser.parse("node 0x_123") }
    expect_raises(Exception) { parser.parse("node 0xg") }
    expect_raises(Exception) { parser.parse("node 0xx") }
  end

  it "parses octal" do
    parser.parse("node 0o01234567").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(342391i64)])])
    parser.parse("node 0o0123_4567").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(342391i64)])])
    parser.parse("node 0o01234567_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(342391i64)])])
    expect_raises(Exception) { parser.parse("node 0o_123") }
    expect_raises(Exception) { parser.parse("node 0o8") }
    expect_raises(Exception) { parser.parse("node 0oo") }
  end

  it "parses binary" do
    parser.parse("node 0b0101").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(5i64)])])
    parser.parse("node 0b01_10").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(6i64)])])
    parser.parse("node 0b01___10").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(6i64)])])
    parser.parse("node 0b0110_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(6i64)])])
    expect_raises(Exception) { parser.parse("node 0b_0110") }
    expect_raises(Exception) { parser.parse("node 0b20") }
    expect_raises(Exception) { parser.parse("node 0bb") }
  end

  it "parses raw string" do
    parser.parse(%(node #"foo"#)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("foo")])])
    parser.parse(%(node #"foo\\nbar"#)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("foo\\nbar")])])
    parser.parse(%(node #"foo"#)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("foo")])])
    parser.parse(%(node ##"foo"##)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("foo")])])
    parser.parse(%(node #"\\nfoo\\r"#)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new("\\nfoo\\r")])])
    expect_raises(Exception) { parser.parse(%(node ##"foo"#)) }
  end

  it "parses boolean" do
    parser.parse("node #true").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(true)])])
    parser.parse("node #false").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(false)])])
  end

  it "parses null" do
    parser.parse("node #null").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(nil)])])
  end

  it "parses node space" do
    parser.parse("node 1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1i64)])])
    parser.parse("node\t1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1i64)])])
    parser.parse("node\t \\ // hello\n 1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1i64)])])
  end

  it "parses single line comment" do
    parser.parse("//hello").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("// \thello").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("//hello\n").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("//hello\r\n").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("//hello\n\r").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("//hello\rworld").should eq KDL::Document.new([KDL::Node.new("world")])
    parser.parse("//hello\nworld\r\n").should eq KDL::Document.new([KDL::Node.new("world")])
  end

  it "parses multi line comment" do
    parser.parse("/*hello*/").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/*hello*/\n").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/*\nhello\r\n*/").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/*\nhello** /\n*/").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/**\nhello** /\n*/").should eq KDL::Document.new([] of KDL::Node)
    parser.parse("/*hello*/world").should eq KDL::Document.new([KDL::Node.new("world")])
  end

  it "parses escline" do
    parser.parse("node\\\n  1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Value.new(1i64)])])
    parser.parse("node\\\n").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node\\ \n").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node\\\n ").should eq KDL::Document.new([KDL::Node.new("node")])
  end

  it "parses whitespace" do
    parser.parse(" node").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("\tnode").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("/* \nfoo\r\n */ etc").should eq KDL::Document.new([KDL::Node.new("etc")])
  end

  it "parses newline" do
    parser.parse("node1\nnode2").should eq KDL::Document.new([KDL::Node.new("node1"), KDL::Node.new("node2")])
    parser.parse("node1\rnode2").should eq KDL::Document.new([KDL::Node.new("node1"), KDL::Node.new("node2")])
    parser.parse("node1\r\nnode2").should eq KDL::Document.new([KDL::Node.new("node1"), KDL::Node.new("node2")])
    parser.parse("node1\n\nnode2").should eq KDL::Document.new([KDL::Node.new("node1"), KDL::Node.new("node2")])
  end

  it "parses basic" do
    doc = parser.parse(%(title "Hello, World"))
    nodes = KDL::Document.new([
      KDL::Node.new("title", arguments: [KDL::Value.new("Hello, World")]),
    ])
    doc.should eq nodes
  end

  it "parses multiple values" do
    doc = parser.parse("bookmarks 12 15 188 1234")
    nodes = KDL::Document.new([
      KDL::Node.new("bookmarks", arguments: [KDL::Value.new(12i64), KDL::Value.new(15i64), KDL::Value.new(188i64), KDL::Value.new(1234i64)]),
    ])
    doc.should eq nodes
  end

  it "parses properties" do
    doc = parser.parse <<-KDL.strip
    author "Alex Monad" email="alex@example.com" active= #true
    foo bar =#true "baz" quux =\\
      #false 1 2 3
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("author",
        arguments: [KDL::Value.new("Alex Monad")],
        properties: {
          "email" => KDL::Value.new("alex@example.com"),
          "active" => KDL::Value.new(true)
        }
      ),
      KDL::Node.new("foo",
        arguments: [KDL::Value.new("baz"), KDL::Value.new(1i64), KDL::Value.new(2i64), KDL::Value.new(3i64)],
        properties: {
          "bar" => KDL::Value.new(true),
          "quux" => KDL::Value.new(false)
        }
      )
    ])
    doc.should eq nodes
  end

  it "parses nested child nodes" do
    doc = parser.parse <<-KDL.strip
    contents {
      section "First section" {
        paragraph "This is the first paragraph"
        paragraph "This is the second paragraph"
      }
    }
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("contents", children: [
        KDL::Node.new("section", arguments: [KDL::Value.new("First section")], children: [
          KDL::Node.new("paragraph", arguments: [KDL::Value.new("This is the first paragraph")]),
          KDL::Node.new("paragraph", arguments: [KDL::Value.new("This is the second paragraph")])
        ])
      ])
    ])
    doc.should eq nodes
  end

  it "parses semicolon" do
    doc = parser.parse("node1; node2; node3;")
    nodes = KDL::Document.new([
      KDL::Node.new("node1"),
      KDL::Node.new("node2"),
      KDL::Node.new("node3")
    ])
    doc.should eq nodes
  end

  it "parses optional child semicolon" do
    doc = parser.parse("node {foo;bar;baz}")
    nodes = KDL::Document.new([
      KDL::Node.new("node", children: [
        KDL::Node.new("foo"),
        KDL::Node.new("bar"),
        KDL::Node.new("baz")
      ])
    ])
    doc.should eq nodes
  end

  it "parses raw strings" do
    doc = parser.parse <<-KDL.strip
    node "this\\nhas\\tescapes"
    other #"C:\\Users\\zkat\\"#
    other-raw #"hello"world"#
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("node", arguments: [KDL::Value.new("this\nhas\tescapes")]),
      KDL::Node.new("other", arguments: [KDL::Value.new("C:\\Users\\zkat\\")]),
      KDL::Node.new("other-raw", arguments: [KDL::Value.new("hello\"world")])
    ])
    doc.should eq nodes
  end

  it "parses multiline strings" do
    doc = parser.parse <<-KDL.strip
    string "my
    multiline
    value"
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("string", arguments: [KDL::Value.new("my\nmultiline\nvalue")])
    ])
    doc.should eq nodes
  end

  it "parses numbers" do
    doc = parser.parse <<-KDL.strip
    num 1.234e-42
    my-hex 0xdeadbeef
    my-octal 0o755
    my-binary 0b10101101
    bignum 1_000_000
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("num", arguments: [KDL::Value.new(1.234e-42)]),
      KDL::Node.new("my-hex", arguments: [KDL::Value.new(0xdeadbeef)]),
      KDL::Node.new("my-octal", arguments: [KDL::Value.new(493i64)]),
      KDL::Node.new("my-binary", arguments: [KDL::Value.new(173i64)]),
      KDL::Node.new("bignum", arguments: [KDL::Value.new(1000000i64)])
    ])
    doc.should eq nodes
  end

  it "parses comments" do
    doc = parser.parse <<-KDL.strip
    // C style

    /*
    C style multiline
    */

    tag /*foo=#true*/ bar=#false

    /*/*
    hello
    */*/
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("tag", properties: { "bar" => KDL::Value.new(false) })
    ])
    doc.should eq nodes
  end

  it "parses slash dash" do
    doc = parser.parse <<-KDL.strip
    /-mynode "foo" key=1 {
      a
      b
      c
    }

    mynode /- "commented" "not commented" /-key="value" /-{
      a
      b
    }
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("mynode", arguments: [KDL::Value.new("not commented")])
    ])
    doc.should eq nodes
  end

  it "parses multiline nodes" do
    doc = parser.parse <<-KDL.strip
    title \\
      "Some title"

    my-node 1 2 \\  // comments are ok after \\
            3 4
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("title", arguments: [KDL::Value.new("Some title")]),
      KDL::Node.new("my-node", arguments: [KDL::Value.new(1i64), KDL::Value.new(2i64), KDL::Value.new(3i64), KDL::Value.new(4i64)])
    ])
    doc.should eq nodes
  end

  it "parses utf8" do
    doc = parser.parse <<-KDL.strip
    smile "😁"
    ノード お名前＝"☜(ﾟヮﾟ☜)"
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("smile", arguments: [KDL::Value.new("😁")]),
      KDL::Node.new("ノード", properties: { "お名前" => KDL::Value.new("☜(ﾟヮﾟ☜)") })
    ])
    doc.should eq nodes
  end

  it "parses node names" do
    doc = parser.parse <<-KDL.strip
    "!@$@$%Q$%~@!40" "1.2.3" "!!!!!"=#true
    foo123~!@$%^&*.:'|?+ "weeee"
    - 1
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new(%(!@$@$%Q$%~@!40), arguments: [KDL::Value.new("1.2.3")], properties: { "!!!!!" => KDL::Value.new(true) }),
      KDL::Node.new(%(foo123~!@$%^&*.:'|?+), arguments: [KDL::Value.new("weeee")]),
      KDL::Node.new("-", arguments: [KDL::Value.new(1i64)])
    ])
    doc.should eq nodes
  end

  it "parses escaping" do
    doc = parser.parse <<-KDL.strip
    node1 "\\u{1f600}"
    node2 "\\n\\t\\r\\\\\\"\\f\\b"
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("node1", arguments: [KDL::Value.new("😀")]),
      KDL::Node.new("node2", arguments: [KDL::Value.new("\n\t\r\\\"\f\b")])
    ])
    doc.should eq nodes
  end

  it "parses node type" do
    doc = parser.parse("(foo)node")
    nodes = KDL::Document.new([
      KDL::Node.new("node", type: "foo")
    ])
    doc.should eq nodes
  end

  it "parses value type" do
    doc = parser.parse(%(node (foo)"bar"))
    nodes = KDL::Document.new([
      KDL::Node.new("node", arguments: [KDL::Value.new("bar").as_type("foo")])
    ])
    doc.should eq nodes
  end

  it "parses property type" do
    doc = parser.parse(%(node baz=(foo)"bar"))
    nodes = KDL::Document.new([
      KDL::Node.new("node", properties: { "baz" => KDL::Value.new("bar").as_type("foo")})
    ])
    doc.should eq nodes
  end

  it "parses child type" do
    doc = parser.parse <<-KDL.strip
    node {
      (foo)bar
    }
    KDL
    nodes = KDL::Document.new([
      KDL::Node.new("node", children: [
        KDL::Node.new("bar", type: "foo")
      ]),
    ])
    doc.should eq nodes
  end
end
