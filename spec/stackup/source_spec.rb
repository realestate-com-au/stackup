require "spec_helper"

require "multi_json"
require "stackup/source"
require "stackup/yaml"

describe Stackup::Source do

  let(:example_dir) { File.expand_path("../../examples", __dir__) }

  context "from a JSON file" do

    let(:json_file) { File.join(example_dir, "template.json") }

    subject(:src) { described_class.new(json_file) }

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

    it "is not S3" do
      expect(subject).not_to be_s3
    end

  end

  context "from a YAML file" do

    let(:yaml_file) { File.join(example_dir, "template.yml") }

    subject(:src) { described_class.new(yaml_file) }

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

    subject(:src) { described_class.new(bogus_file) }

    describe "#body" do

      it "raises a ReadError" do
        expect { subject.body }.to raise_error(Stackup::Source::ReadError, 'no such file: "notreallythere.json"')
      end

    end

  end

  context "with an HTTP URL" do

    let(:url) { "https://example.com/template.json" }

    subject(:src) { described_class.new(url) }

    it "is not S3" do
      expect(subject).not_to be_s3
    end

  end

  context "with an S3 URL" do

    let(:s3_url) { "https://s3.amazonaws.com/bucket/template.json" }

    subject(:src) { described_class.new(s3_url) }

    context "with bucket in path" do

      let(:s3_url) { "https://s3.amazonaws.com/bucket/template.json" }

      it "is S3" do
        expect(subject).to be_s3
      end

    end

    context "with bucket in host" do

      let(:s3_url) { "https://bucket.s3.amazonaws.com/template.json" }

      it "is S3" do
        expect(subject).to be_s3
      end

    end

    context "with bucket region" do

      let(:s3_url) { "https://bucket.s3-ap-northeast-3.amazonaws.com/template.json" }

      it "is S3" do
        expect(subject).to be_s3
      end

    end

  end

end
