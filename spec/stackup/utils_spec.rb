# frozen_string_literal: true

require "spec_helper"

require "stackup/utils"

describe Stackup::Utils do

  include Stackup::Utils

  describe ".normalize_data" do

    context "with a scalar" do

      it "returns the input" do
        expect(normalize_data(123)).to eql(123)
      end

    end

    context "with a Hash" do

      it "sorts the Hash" do
        input = {
          "foo" => 1,
          "bar" => 2
        }
        expected_output = {
          "bar" => 2,
          "foo" => 1
        }
        expect(normalize_data(input)).to eql(expected_output)
      end

    end

    context "with a nested Hash" do

      it "sorts the Hash" do
        input = {
          "stuff" => {
            "foo" => 1,
            "bar" => 2
          }
        }
        expected_output = {
          "stuff" => {
            "bar" => 2,
            "foo" => 1
          }
        }
        expect(normalize_data(input)).to eql(expected_output)
      end

    end

    context "with an array of Hashes" do

      it "sorts the all" do
        input = [
          {
            "foo" => 1,
            "bar" => 2
          }
        ]
        expected_output = [
          {
            "bar" => 2,
            "foo" => 1
          }
        ]
        expect(normalize_data(input)).to eql(expected_output)
      end

    end

  end
end
