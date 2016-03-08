require "spec_helper"

require "stackup/parameters"

describe Stackup::Parameters do

  context "constructed with a Hash" do

    let(:input_hash) do
      {
        "Ami" => "ami-123",
        "VpcId" => "vpc-456"
      }
    end

    subject(:parameters) { Stackup::Parameters.new(input_hash) }

    describe "#to_hash" do

      it "returns the original Hash" do
        expect(parameters.to_hash).to eql(input_hash)
      end

    end

    describe "#to_a" do

      it "returns an array of parameter records" do
        expected = [
          { :parameter_key => "Ami", :parameter_value => "ami-123" },
          { :parameter_key => "VpcId", :parameter_value => "vpc-456" }
        ]
        expect(parameters.to_a).to eql(expected)
      end

    end

  end

  context "constructed with an array of parameter records" do

    context "with symbol keys" do

      let(:input_records) do
        [
          { :parameter_key => "Ami", :parameter_value => "ami-123" },
          { :parameter_key => "VpcId", :parameter_value => "vpc-456" }
        ]
      end

      subject(:parameters) { Stackup::Parameters.new(input_records) }

      describe "#to_hash" do

        it "returns an equivalent Hash" do
          expected = {
            "Ami" => "ami-123",
            "VpcId" => "vpc-456"
          }
          expect(parameters.to_hash).to eql(expected)
        end

      end

      describe "#to_a" do

        it "returns the array form" do
          expect(parameters.to_a).to eql(input_records)
        end

      end

    end

  end

end
