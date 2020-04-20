require "spec_helper"
require "stackup/rake_tasks"

RSpec.describe Stackup::RakeTasks do
  it "can be required" do
    expect(described_class).to be_truthy
  end
end
