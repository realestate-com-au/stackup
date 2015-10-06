require "aws-sdk-core"

module Stackup
  class Monitor

    attr_accessor :stack, :events
    def initialize(stack)
      @stack = stack
      @events = Set.new
    end

    def new_events
      stack.events.take_while do |event|
        !seen?(event)
      end.reverse
    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      []
    end

    private

    def seen?(event)
      event_id = event.event_id
      if events.include?(event_id)
        true
      else
        events.add(event_id)
        false
      end
    end

  end
end
