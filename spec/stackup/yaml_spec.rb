require "spec_helper"

require "stackup/yaml"

describe Stackup::YAML do

  describe ".load" do

    let(:data) do
      described_class.load(input)
    end

    describe "plain YAML" do

      let(:input) do
        <<-YAML
        Outputs:
          Foo: "bar"
        YAML
      end

      it "loads as normal" do
        expect(data).to eql(
          "Outputs" => {
            "Foo" => "bar"
          }
        )
      end

    end

    describe "!Ref" do

      let(:input) do
        <<-YAML
        Outputs:
          Foo: !Ref "Bar"
        YAML
      end

      it "expands to Ref" do
        expect(data).to eql(
          "Outputs" => {
            "Foo" => {
              "Ref" => "Bar"
            }
          }
        )
      end

    end

    describe "!GetAtt" do

      context "with an array" do

        let(:input) do
          <<-YAML
          Outputs:
            Foo: !GetAtt [Bar, Baz]
          YAML
        end

        it "expands to Fn::GetAtt" do
          expect(data).to eql(
            "Outputs" => {
              "Foo" => {
                "Fn::GetAtt" => [
                  "Bar",
                  "Baz"
                ]
              }
            }
          )
        end

      end

      context "with a string" do

        let(:input) do
          <<-YAML
          Outputs:
            Foo: !GetAtt Bar.Baz
          YAML
        end

        it "split on dot" do
          expect(data).to eql(
            "Outputs" => {
              "Foo" => {
                "Fn::GetAtt" => [
                  "Bar",
                  "Baz"
                ]
              }
            }
          )
        end

      end

      context "with a string with multiple dots" do

        let(:input) do
          <<-YAML
          Outputs:
            Foo: !GetAtt Bar.Baz.Some.More.Things
          YAML
        end

        it "splits on the first dot" do
          expect(data).to eql(
            "Outputs" => {
              "Foo" => {
                "Fn::GetAtt" => [
                  "Bar",
                  "Baz.Some.More.Things"
                ]
              }
            }
          )
        end

      end

    end

    describe "!GetAZs" do

      context "with an argument" do

        let(:input) do
          <<-YAML
            Foo:
              !GetAZs xy-foobar-6
          YAML
        end

        it "expands to Fn::GetAtt" do
          expect(data).to eql(
            "Foo" => {
              "Fn::GetAZs" => "xy-foobar-6"
            }
          )
        end

      end

      context "without an argument" do

        let(:input) do
          <<-YAML
            Foo:
              !GetAZs
          YAML
        end

        it "infers a blank argument" do
          expect(data).to eql(
            "Foo" => {
              "Fn::GetAZs" => ""
            }
          )
        end

      end

    end

    describe "!Whatever" do

      let(:input) do
        <<-YAML
          Stuff:
          - !FindInMap [RegionMap, !Ref "AWS::Region", AMI]
          - !If [CreateProdResources, c1.xlarge, m1.small]
          - !Join [ ":", [ "a", "b", "c" ] ]
        YAML
      end

      it "expands to Fn::Whatever" do
        expect(data).to eql(
          "Stuff" => [
            {
              "Fn::FindInMap" => ["RegionMap", {"Ref"=>"AWS::Region"}, "AMI"]
            },
            {
              "Fn::If" => ["CreateProdResources", "c1.xlarge", "m1.small"]
            },
            {
              "Fn::Join" => [":", ["a", "b", "c"]]
            }
          ]
        )
      end

    end

  end

end
