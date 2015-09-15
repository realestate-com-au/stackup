require "spec_helper"

describe Stackup::Monitor do
  let(:stack) { Stackup::Stack.new("name", "template") }
  let(:monitor) { Stackup::Monitor.new(stack) }
  let(:event) { double(Aws::CloudFormation::Event.new(:id => "1")) }
  let(:events) { [event] }

  before do
    ENV['AWS_REGION'] = 'ap-southeast-2'
    allow(event).to receive(:event_id).and_return("1")
    allow(stack).to receive(:events).and_return(events)
  end

  it "should add the event if it is non-existent" do
    expect(monitor.new_events.size).to eq(1)
  end

  it "should skip the event if it has been shown" do
    expect(monitor.new_events.size).to eq(1)
    expect(monitor.new_events.size).to eq(0)
  end
end
