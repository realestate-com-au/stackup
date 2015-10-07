require "aws-sdk-core"

module Stackup

  class StackWatcher

    def initialize(stack)
      @stack = stack
      @processed_event_ids = Set.new
    end

    attr_accessor :stack

    # Yield all events since the last call
    #
    def new_events
      [].tap do |events|
        stack.events.each do |event|
          break if @processed_event_ids.include?(event.event_id)
          events.unshift(event)
          @processed_event_ids.add(event.event_id)
        end
      end
    rescue ::Aws::CloudFormation::Errors::ValidationError
      []
    end

    # Consume all new events
    #
    def zero
      new_events
      nil
    end

    private

    attr_accessor :processed_event_ids

  end

end
