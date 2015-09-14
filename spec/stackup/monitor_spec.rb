require 'spec_helper'

describe Stackup::Monitor do
  let(:stack) { Stackup::Stack.new('name', 'template') }
  let(:monitor) { Stackup::Monitor.new(stack) }

  it 'should add the event if it is non-existent' do
    allow(stack).to receive(:events).and_return([])
    expect(monitor.new_events).to eq(1)
  end

  it 'should skip the event if it has been shown' do
    allow(stack).to receive(:events).and_return([])
    expect(monitor.new_events).to eq(1)
  end
end
