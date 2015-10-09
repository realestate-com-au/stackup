require "aws-sdk-core"

module Stackup

  # A stack event observer.
  #
  # Keeps track of previously processed events, and yields the new ones.
  #
  class StackWatcher

    def initialize(stack)
      @stack = stack
      @processed_event_ids = Set.new
    end

    attr_accessor :stack

    # Yield all events since the last call
    #
    def each_new_event
      # rubocop:disable Lint/HandleExceptions
      buffer = []
      stack.events.each do |event|
        break if @processed_event_ids.include?(event.event_id)
        buffer.unshift(event)
      end
      buffer.each do |event|
        yield event if block_given?
        @processed_event_ids.add(event.event_id)
      end
    rescue Aws::CloudFormation::Errors::ValidationError
    end

    # Consume all new events
    #
    def zero
      each_new_event
      nil
    end

    private

    attr_accessor :processed_event_ids

  end

end
