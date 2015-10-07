require "spec_helper"

require "stackup/stack_watcher"

describe Stackup::StackWatcher do

  let(:stack) { instance_double(Aws::CloudFormation::Stack, :events => events) }
  let(:events) { [] }

  subject(:monitor) { described_class.new(stack) }

  def add_event(description)
    @event_id ||= 0
    event = instance_double(
      Aws::CloudFormation::Event,
      :event_id => @event_id, :resource_status_reason => description
    )
    events.unshift(event)
    @event_id += 1
  end

  context "with a empty set of events" do

    describe "#new_events" do

      it "is empty" do
        expect(subject.new_events).to be_empty
      end

    end

  end

  context "when the stack does not exist" do

    before do
      allow(stack).to receive(:events) do
        fail Aws::CloudFormation::Errors::ValidationError.new("test", "no such stack")
      end
    end

    describe "#new_events" do

      it "is empty" do
        expect(subject.new_events).to be_empty
      end

    end

  end

  def new_event_reasons
    subject.new_events.map(&:resource_status_reason)
  end

  context "when the stack has existing events" do

    before do
      add_event("earlier")
      add_event("later")
    end

    describe "#new_events" do

      it "returns the events in the order they occurred" do
        expect(new_event_reasons).to eq(["earlier", "later"])
      end

    end

    context "and more events occur" do

      before do
        subject.new_events
        add_event("even")
        add_event("more")
      end

      describe "#new_events" do

        it "returns only the new events" do
          expect(new_event_reasons).to eq(["even", "more"])
        end

      end

    end

  end

end
