require "../spec_helper"

describe KDL::Value do
  describe "#to_s" do
    it "returns stringified value" do
      KDL::Value.new(1).to_s.should eq "1"
      KDL::Value.new(1, type: "foo").to_s.should eq "(foo)1"
      KDL::Value.new(1, type: "foo\"bar").to_s.should eq "(\"foo\\\"bar\")1"
      KDL::Value.new(1.5).to_s.should eq "1.5"
      KDL::Value.new(BigDecimal.new("1.5e1000")).to_s.should eq "1.5E+1000"
      KDL::Value.new(BigDecimal.new("1.5e-1000")).to_s.should eq "1.5E-1000"
      KDL::Value.new(Float64::INFINITY).to_s.should eq "#inf"
      KDL::Value.new(-Float64::INFINITY).to_s.should eq "#-inf"
      KDL::Value.new(Float64::NAN).to_s.should eq "#nan"
      KDL::Value.new(true).to_s.should eq "#true"
      KDL::Value.new(false).to_s.should eq "#false"
      KDL::Value.new(nil).to_s.should eq "#null"
      KDL::Value.new("foo").to_s.should eq "foo"
      KDL::Value.new("foo \"bar\" baz").to_s.should eq "\"foo \\\"bar\\\" baz\""
    end
  end
end
