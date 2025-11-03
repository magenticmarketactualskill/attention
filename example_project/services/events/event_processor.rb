class EventProcessor
  def process(event)
    # Process incoming events
    validate_event(event)
    store_event(event)
    notify_subscribers(event)
  end

  private

  def validate_event(event)
    raise ArgumentError unless event.valid?
  end

  def store_event(event)
    EventStore.save(event)
  end

  def notify_subscribers(event)
    EventNotifier.notify(event)
  end
end
