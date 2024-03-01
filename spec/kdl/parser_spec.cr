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
    parser.parse("node 1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(1)])])
    parser.parse(%(node 1 2 "3" #true #false #null)).should eq KDL::Document.new([
      KDL::Node.new("node", arguments: [
        KDL::Int.new(1),
        KDL::Int.new(2),
        KDL::String.new("3"),
        KDL::Bool.new(true),
        KDL::Bool.new(false),
        KDL::Null()
      ])
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
    parser.parse("node /-1 2").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(2)])])
    parser.parse("node 1 /- 2 3").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(1), KDL::Int.new(3)])])
    parser.parse("node /--1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /- -1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node \\\n/- -1").should eq KDL::Document.new([KDL::Node.new("node")])
  end

  it "parses prop slashdash comment" do
    parser.parse("node /-key=1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /- key=1").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node key=1 /-key2=2").should eq KDL::Document.new([KDL::Node.new("node", properties: { "key" => KDL::Int.new(1) })])
  end

  it "parses children slashdash comment" do
    parser.parse("node /-{}").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /- {}").should eq KDL::Document.new([KDL::Node.new("node")])
    parser.parse("node /-{\nnode2\n}").should eq KDL::Document.new([KDL::Node.new("node")])
  end

  it "parses string" do
    parser.parse(%(node "")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("")])])
    parser.parse(%(node "hello")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("hello")])])
    parser.parse(%(node "hello\nworld")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("hello\nworld")])])
    parser.parse(%(node -flag)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("-flag")])])
    parser.parse(%(node --flagg)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("--flagg")])])
    parser.parse(%(node "\u{10FFF}")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("\u{10FFF}")])])
    parser.parse(%(node "\"\\\b\f\n\r\t")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("\"\\\u{08}\u{0C}\n\r\t")])])
    parser.parse(%(node "\u{10}")).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("\u{10}")])])
    expect_raises(Exception) { parser.parse(%(node "\i")) }
    expect_raises(Exception) { parser.parse(%(node "\\u{c0ffee}")) }
  end

  it "parses unindented multiline strings" do
    parser.parse("node \"\n  foo\n  bar\n    baz\n  qux\n  \"").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("foo\nbar\n  baz\nqux")])])
    parser.parse("node #\"\n  foo\n  bar\n    baz\n  qux\n  \"#").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("foo\nbar\n  baz\nqux")])])
    expect_raises(Exception) { parser.parse("node \"\n    foo\n  bar\n    baz\n    \"") }
    expect_raises(Exception) { parser.parse("node #\"\n    foo\n  bar\n    baz\n    \"#") }
  end

  it "parses float" do
    parser.parse("node 1.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Decimal.from(1.0)])])
    parser.parse("node 0.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Decimal.from(0.0)])])
    parser.parse("node -1.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Decimal.from(-1.0)])])
    parser.parse("node +1.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Decimal.from(1.0)])])
    parser.parse("node 1.0e10").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Decimal.from(1.0e10)])])
    parser.parse("node 1.0e-10").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Decimal.from(1.0e-10)])])
    parser.parse("node 123_456_789.0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Decimal.from(123456789.0)])])
    parser.parse("node 123_456_789.0_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Decimal.from(123456789.0)])])
    expect_raises(Exception) { parser.parse("node 1._0") }
    expect_raises(Exception) { parser.parse("node 1.") }
    expect_raises(Exception) { parser.parse("node 1.0v2") }
    expect_raises(Exception) { parser.parse("node -1em") }
    expect_raises(Exception) { parser.parse("node .0") }
  end

  it "parses integer" do
    parser.parse("node 0").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(0)])])
    parser.parse("node 0123456789").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(123456789)])])
    parser.parse("node 0123_456_789").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(123456789)])])
    parser.parse("node 0123_456_789_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(123456789)])])
    parser.parse("node +0123456789").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(123456789)])])
    parser.parse("node -0123456789").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(-123456789)])])
  end

  it "parses hexadecimal" do
    parser.parse("node 0x0123456789abcdef").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(0x0123456789abcdef)])])
    parser.parse("node 0x01234567_89abcdef").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(0x0123456789abcdef)])])
    parser.parse("node 0x01234567_89abcdef_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(0x0123456789abcdef)])])
    expect_raises(Exception) { parser.parse("node 0x_123") }
    expect_raises(Exception) { parser.parse("node 0xg") }
    expect_raises(Exception) { parser.parse("node 0xx") }
  end

  it "parses octal" do
    parser.parse("node 0o01234567").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(342391)])])
    parser.parse("node 0o0123_4567").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(342391)])])
    parser.parse("node 0o01234567_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(342391)])])
    expect_raises(Exception) { parser.parse("node 0o_123") }
    expect_raises(Exception) { parser.parse("node 0o8") }
    expect_raises(Exception) { parser.parse("node 0oo") }
  end

  it "parses binary" do
    parser.parse("node 0b0101").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(5)])])
    parser.parse("node 0b01_10").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(6)])])
    parser.parse("node 0b01___10").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(6)])])
    parser.parse("node 0b0110_").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(6)])])
    expect_raises(Exception) { parser.parse("node 0b_0110") }
    expect_raises(Exception) { parser.parse("node 0b20") }
    expect_raises(Exception) { parser.parse("node 0bb") }
  end

  it "parses raw string" do
    parser.parse(%(node #"foo"#)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("foo")])])
    parser.parse(%(node #"foo\nbar"#)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new(%(foo\nbar))])])
    parser.parse(%(node #"foo"#)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("foo")])])
    parser.parse(%(node ##"foo"##)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new("foo")])])
    parser.parse(%(node #"\nfoo\r"#)).should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::String.new(%(\nfoo\r))])])
    expect_raises(Exception) { parser.parse(%(node ##"foo"#)) }
  end

  it "parses boolean" do
    parser.parse("node #true").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Bool.new(true)])])
    parser.parse("node #false").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Bool.new(false)])])
  end

  it "parses null" do
    parser.parse("node #null").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Null()])])
  end

  it "parses node space" do
    parser.parse("node 1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(1)])])
    parser.parse("node\t1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(1)])])
    parser.parse("node\t \\ // hello\n 1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(1)])])
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
    parser.parse("node\\\n  1").should eq KDL::Document.new([KDL::Node.new("node", arguments: [KDL::Int.new(1)])])
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
    var doc = parser.parse(%(title "Hello, World"))
    var nodes = KDL::Document.new([
      KDL::Node.new("title", arguments: [KDL::String.new("Hello, World")]),
    ])
    doc.should eq nodes
  end

  it "parses multiple values" do
    var doc = parser.parse("bookmarks 12 15 188 1234")
    var nodes = KDL::Document.new([
      KDL::Node.new("bookmarks", arguments: [KDL::Int.new(12), KDL::Int.new(15), KDL::Int.new(188), KDL::Int.new(1234)]),
    ])
    doc.should eq nodes
  end

  it "parses properties" do
    var doc = parser.parse <<-KDL.strip
    author "Alex Monad" email="alex@example.com" active= #true
    foo bar =#true "baz" quux =\\
      #false 1 2 3
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("author",
        arguments: [KDL::String.new("Alex Monad")],
        properties: {
          "email" => KDL::String.new("alex@example.com"),
          "active" => KDL::Bool.new(true)
        }
      ),
      KDL::Node.new("foo",
        arguments: [KDL::String.new("baz"), KDL::Int.new(1), KDL::Int.new(2), KDL::Int.new(3)],
        properties: {
          "bar" => KDL::Bool.new(true),
          "quux" => KDL::Bool.new(false)
        }
      )
    ])
    doc.should eq nodes
  end

  it "parses nested child nodes" do
    var doc = parser.parse <<-KDL.strip
    contents {
      section "First section" {
        paragraph "This is the first paragraph"
        paragraph "This is the second paragraph"
      }
    }
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("contents", children: [
        KDL::Node.new("section", arguments: [KDL::String.new("First section")], children: [
          KDL::Node.new("paragraph", arguments: [KDL::String.new("This is the first paragraph")]),
          KDL::Node.new("paragraph", arguments: [KDL::String.new("This is the second paragraph")])
        ])
      ])
    ])
    doc.should eq nodes
  end

  it "parses semicolon" do
    var doc = parser.parse("node1; node2; node3;")
    var nodes = KDL::Document.new([
      KDL::Node.new("node1"),
      KDL::Node.new("node2"),
      KDL::Node.new("node3")
    ])
    doc.should eq nodes
  end

  it "parses optional child semicolon" do
    var doc = parser.parse("node {foo;bar;baz}")
    var nodes = KDL::Document.new([
      KDL::Node.new("node", children: [
        KDL::Node.new("foo"),
        KDL::Node.new("bar"),
        KDL::Node.new("baz")
      ])
    ])
    doc.should eq nodes
  end

  it "parses raw strings" do
    var doc = parser.parse <<-KDL.strip
    node "this\\nhas\\tescapes"
    other #"C:\\Users\\zkat\\"#
    other-raw #"hello"world"#
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("node", arguments: [KDL::String.new("this\nhas\tescapes")]),
      KDL::Node.new("other", arguments: [KDL::String.new("C:\\Users\\zkat\\")]),
      KDL::Node.new("other-raw", arguments: [KDL::String.new("hello\"world")])
    ])
    doc.should eq nodes
  end

  it "parses multiline strings" do
    var doc = parser.parse <<-KDL.strip
    string "my
    multiline
    value"
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("string", arguments: [KDL::String.new("my\nmultiline\nvalue")])
    ])
    doc.should eq nodes
  end

  it "parses numbers" do
    var doc = parser.parse <<-KDL.strip
    num 1.234e-42
    my-hex 0xdeadbeef
    my-octal 0o755
    my-binary 0b10101101
    bignum 1_000_000
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("num", arguments: [KDL::Decimal.new(BigDecimal.new("1.234e-42"))]),
      KDL::Node.new("my-hex", arguments: [KDL::Int.new(0xdeadbeef)]),
      KDL::Node.new("my-octal", arguments: [KDL::Int.new(493)]),
      KDL::Node.new("my-binary", arguments: [KDL::Int.new(173)]),
      KDL::Node.new("bignum", arguments: [KDL::Int.new(1000000)])
    ])
    doc.should eq nodes
  end

  it "parses comments" do
    var doc = parser.parse <<-KDL.strip
    // C style

    /*
    C style multiline
    */

    tag /*foo=#true*/ bar=#false

    /*/*
    hello
    */*/
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("tag", properties: { "bar": KDL::Bool.new(false) })
    ])
    doc.should eq nodes
  end

  it "parses slash dash" do
    var doc = parser.parse <<-KDL.strip
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
    var nodes = KDL::Document.new([
      KDL::Node.new("mynode", arguments: [KDL::String.new("not commented")])
    ])
    doc.should eq nodes
  end

  it "parses multiline nodes" do
    var doc = parser.parse <<-KDL.strip
    title \\
      "Some title"

    my-node 1 2 \\  // comments are ok after \\
            3 4
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("title", arguments: [KDL::String.new("Some title")]),
      KDL::Node.new("my-node", arguments: [KDL::Int.new(1), KDL::Int.new(2), KDL::Int.new(3), KDL::Int.new(4)])
    ])
    doc.should eq nodes
  end

  it "parses utf8" do
    var doc = parser.parse <<-KDL.strip
    smile "😁"
    ノード お名前＝"☜(ﾟヮﾟ☜)"
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("smile", arguments: [KDL::String.new("😁")]),
      KDL::Node.new("ノード", properties: { "お名前" => KDL::String.new("☜(ﾟヮﾟ☜)") })
    ])
    doc.should eq nodes
  end

  it "parses node names" do
    var doc = parser.parse <<-KDL.strip
    "!@$@$%Q$%~@!40" "1.2.3" "!!!!!"=#true
    foo123~!@$%^&*.:'|?+ "weeee"
    - 1
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new(%("!@$@$%Q$%~@!40), arguments: [KDL::String.new("1.2.3")], properties: { "!!!!!" => KDL::Bool.new(true) }),
      KDL::Node.new(%("foo123~!@$%^&*.:'|?+), arguments: [KDL::String.new("weeee")]),
      KDL::Node.new("-", arguments: [KDL::Int.new(1)])
    ])
    doc.should eq nodes
  end

  it "parses escaping" do
    var doc = parser.parse <<-KDL.strip
    node1 "\\u{1f600}"
    node2 "\\n\\t\\r\\\\\\"\\f\\b"
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("node1", arguments: [KDL::String.new("😀")]),
      KDL::Node.new("node2", arguments: [KDL::String.new("\n\t\r\\\"\f\b")])
    ])
    doc.should eq nodes
  end

  it "parses node type" do
    var doc = parser.parse("(foo)node")
    var nodes = KDL::Document.new([
      KDL::Node.new("node", type: "foo")
    ])
    doc.should eq nodes
  end

  it "parses value type" do
    var doc = parser.parse(%(node (foo)"bar"))
    var nodes = KDL::Document.new([
      KDL::Node.new("node", arguments: [KDL::String.new("bar").asType("foo")])
    ])
    doc.should eq nodes
  end

  it "parses property type" do
    var doc = parser.parse(%(node baz=(foo)"bar"))
    var nodes = KDL::Document.new([
      KDL::Node.new("node", properties: { "baz" => KDL::String.new("bar").asType("foo")})
    ])
    doc.should eq nodes
  end

  it "parses child type" do
    var doc = parser.parse <<-KDL.strip
    node {
      (foo)bar
    }
    KDL
    var nodes = KDL::Document.new([
      KDL::Node.new("node", children: [
        KDL::Node.new("bar", type: "foo")
      ]),
    ])
    doc.should eq nodes
  end
end
