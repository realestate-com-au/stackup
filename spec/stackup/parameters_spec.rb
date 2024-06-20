# frozen_string_literal: true

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

    context "with a :use_previous_value" do

      let(:input_hash) do
        {
          "Ami" => :use_previous_value
        }
      end

      describe "#to_hash" do

        it "returns the original Hash" do
          expect(parameters.to_hash).to eql(input_hash)
        end

      end

      describe "#to_a" do

        it "returns a record with :use_previous_value true" do
          expected = [
            { :parameter_key => "Ami", :use_previous_value => true }
          ]
          expect(parameters.to_a).to eql(expected)
        end

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

      context "with :use_previous_value" do

        let(:input_records) do
          [
            { :parameter_key => "Ami", :use_previous_value => true }
          ]
        end

        describe "#to_hash" do

          it "marks the corresponding parameter as :use_previous_value" do
            expect(parameters.to_hash).to eql("Ami" => :use_previous_value)
          end

        end

      end

    end

    context "with String keys" do

      let(:input_records) do
        [
          { "ParameterKey" => "Ami", "ParameterValue" => "ami-123" },
          { "ParameterKey" => "VpcId", "ParameterValue" => "vpc-456" }
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

    end

    context "with non-string values" do

      let(:input_records) do
        [
          { :parameter_key => "Integer", :parameter_value => 123_456_789 },
          { :parameter_key => "Truthy", :parameter_value => true },
          { :parameter_key => "Falsey", :parameter_value => false },
          { :parameter_key => "Null", :parameter_value => nil },
          { :parameter_key => "Array", :parameter_value => ["one", 2] },
          { :parameter_key => "String", :parameter_value => "string" }
        ]
      end

      subject(:parameters) { Stackup::Parameters.new(input_records) }

      describe "#to_hash" do
        it "converts the to strings where appropriate" do
          expected = {
            "Integer" => "123456789",
            "Truthy" => "true",
            "Falsey" => "false",
            "Null" => nil,
            "Array" => "one,2",
            "String" => "string"
          }
          expect(parameters.to_hash).to eql(expected)
        end
      end

      describe "#to_a" do
        it "converts the to strings where appropriate" do
          expected = [
            { :parameter_key => "Integer", :parameter_value => "123456789" },
            { :parameter_key => "Truthy", :parameter_value => "true" },
            { :parameter_key => "Falsey", :parameter_value => "false" },
            { :parameter_key => "Null", :parameter_value => nil },
            { :parameter_key => "Array", :parameter_value => "one,2" },
            { :parameter_key => "String", :parameter_value => "string" }
          ]
          expect(parameters.to_a).to eql(expected)
        end
      end

    end

    context "with empty parameter file" do

      let(:input_records) { false }

      subject(:parameters) { Stackup::Parameters.new(input_records) }

      describe "#to_hash" do

        it "doesn't crash" do
          expected = {}
          expect(parameters.to_hash).to eql(expected)
        end

      end

    end

  end

end
