require "spec_helper"

require "multi_json"
require "stackup/source"
require "stackup/yaml"

describe Stackup::Source do

  let(:example_dir) { File.expand_path("../../../examples", __FILE__) }

  context "from a JSON file" do

    let(:json_file) { File.join(example_dir, "template.json") }

    subject(:source) { described_class.new(json_file) }

    describe "#body" do

      it "returns JSON body" do
        expect(subject.body).to eql(File.read(json_file))
      end

    end

    describe "#data" do

      it "returns parsed JSON" do
        expect(subject.data).to eql(MultiJson.load(File.read(json_file)))
      end

    end

  end

  context "from a YAML file" do

    let(:yaml_file) { File.join(example_dir, "template.yml") }

    subject(:source) { described_class.new(yaml_file) }

    describe "#body" do

      it "returns YAML body" do
        expect(subject.body).to eql(File.read(yaml_file))
      end

    end

    describe "#data" do

      it "returns parsed YAML" do
        expect(subject.data).to eql(Stackup::YAML.load_file(yaml_file))
      end

    end

  end

  context "with a non-existant file" do

    let(:bogus_file) { "notreallythere.json" }

    subject(:source) { described_class.new(bogus_file) }

    describe "#body" do

      it "raises a ReadError" do
        expect { subject.body }.to raise_error(Stackup::Source::ReadError, %q(no such file: "notreallythere.json"))
      end

    end

  end

end
