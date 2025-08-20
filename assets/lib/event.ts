interface ReconnectOptionsMessage {
  timeout?: number;
  retry?: number;
}

interface EventMessage {
  id: string;
  event: string;
  data: string;
}

export type SquiggleMessage = ReconnectOptionsMessage | EventMessage;

export function isReconnectMessage(
  message: any,
): message is ReconnectOptionsMessage {
  return (
    ("timeout" in message && typeof message.timeout == "number") ||
    ("retry" in message && typeof message.timeout == "number")
  );
}

export function isEventMessage(message: any): message is EventMessage {
  return (
    "id" in message &&
    typeof message.id == "string" &&
    "event" in message &&
    typeof message.event == "string" &&
    "data" in message
  );
}
