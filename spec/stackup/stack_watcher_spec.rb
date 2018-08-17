require "spec_helper"

require "aws-sdk-cloudformation"
require "securerandom"
require "stackup/stack_watcher"

describe Stackup::StackWatcher do

  let(:stack) { instance_double(Aws::CloudFormation::Stack, :events => events) }
  let(:events) { [] }

  subject(:monitor) { described_class.new(stack) }

  def add_event(description)
    event_id = SecureRandom.uuid
    event = instance_double(
      Aws::CloudFormation::Event,
      :event_id => event_id,
      :id => event_id,
      :resource_status_reason => description
    )
    events.unshift(event)
  end

  def new_event_reasons
    [].tap do |result|
      subject.each_new_event do |event|
        result << event.resource_status_reason
      end
    end
  end

  context "with a empty set of events" do

    describe "#each_new_event" do

      it "yields nothing" do
        expect(new_event_reasons).to be_empty
      end

    end

  end

  context "when the stack does not exist" do

    before do
      allow(stack).to receive(:events) do
        raise Aws::CloudFormation::Errors::ValidationError.new("test", "no such stack")
      end
    end

    describe "#each_new_event" do

      it "yields nothing" do
        expect(new_event_reasons).to be_empty
      end

    end

  end

  context "when the stack has existing events" do

    before do
      add_event("earlier")
      add_event("later")
    end

    describe "#each_new_event" do

      it "yields the events in the order they occurred" do
        expect(new_event_reasons).to eq(["earlier", "later"])
      end

    end

    context "and more events occur" do

      before do
        new_event_reasons
        add_event("even")
        add_event("more")
      end

      describe "#each_new_event" do

        it "yields only the new events" do
          expect(new_event_reasons).to eq(["even", "more"])
        end

      end

    end

  end

end
