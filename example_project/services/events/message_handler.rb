class MessageHandler
  def handle(message)
    parse_message(message)
    route_message(message)
  end
end
