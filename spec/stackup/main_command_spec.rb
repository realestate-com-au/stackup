require "stackup/main_command"

describe Stackup::MainCommand do

  let(:mock_change_set) { double() }

  before(:example) do
    mock_stackup = double()
    mock_stack = double()
    allow_any_instance_of(Stackup::MainCommand).to receive(:Stackup).and_return(mock_stackup)
    allow(mock_stackup).to receive(:stack).and_return(mock_stack)
    allow(mock_stack).to receive(:change_set).and_return(mock_change_set)
  end

  context "change-set create --service-role-arn" do
    it "invokes stack.change_set.create with role arn passed through" do
      expected_args = {
        role_arn: "arn:aws:iam::000000000000:role/example"
      }
      expect(mock_change_set).to receive(:create).with(hash_including(expected_args))

      Stackup::MainCommand.run("stackup", [
        "STACK-NAME", "change-set", "create",
        "--template", "examples/template.yml",
        "--service-role-arn", "arn:aws:iam::000000000000:role/example"])
    end
  end

  context "change-set create" do
    it "invokes stack.change_set.create with allow_empty_change_set nil" do
      expected_args = {
        allow_empty_change_set: nil
      }
      expect(mock_change_set).to receive(:create).with(hash_including(expected_args))

      Stackup::MainCommand.run("stackup", [
        "STACK-NAME", "change-set", "create",
        "--template", "examples/template.yml"])
    end
  end

  context "change-set create --no-fail-on-empty-change-set" do
    it "invokes stack.change_set.create with allow_empty_change_set true" do
      expected_args = {
        allow_empty_change_set: true
      }
      expect(mock_change_set).to receive(:create).with(hash_including(expected_args))

      Stackup::MainCommand.run("stackup", [
        "STACK-NAME", "change-set", "create",
        "--template", "examples/template.yml",
        "--no-fail-on-empty-change-set"])
    end
  end

end
