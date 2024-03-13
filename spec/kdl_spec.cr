require "./spec_helper"

describe KDL do

  test_cases = "./spec/kdl-org/tests/test_cases"
  inputs = Dir["#{test_cases}/input/*"]

  inputs.each do |input|
    name = File.basename(input)
    expected = "#{test_cases}/expected_kdl/#{name}"
    if File.exists?(expected)
      it "#{name} matches output" do
        KDL.parse_document(File.read(input)).to_s.should eq File.read(expected)
      end
    else
      it "#{name} does not parse" do
        expect_raises(Exception) { KDL.parse_document(File.read(input)) }
      end
    end
  end

end
