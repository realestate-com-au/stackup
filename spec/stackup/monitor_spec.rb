require "spec_helper"

describe Stackup::Monitor do

  let(:stack) { instance_double(Aws::CloudFormation::Stack, :events => events) }
  let(:monitor) { described_class.new(stack) }

  let(:event) { instance_double(Aws::CloudFormation::Event, :id => "1") }
  let(:events) { [event] }

  before do
    allow(event).to receive(:event_id).and_return("1")
  end

  it "should add the event if it is non-existent" do
    expect(monitor.new_events.size).to eq(1)
  end

  it "should skip the event if it has been shown" do
    expect(monitor.new_events.size).to eq(1)
    expect(monitor.new_events.size).to eq(0)
  end

end
