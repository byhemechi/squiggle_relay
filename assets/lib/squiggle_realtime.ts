import { isEventMessage, isReconnectMessage } from "./event";

export default class SquiggleRealtime extends EventTarget {
  socket: WebSocket;
  #keepAliveTimer?: ReturnType<typeof setInterval>;
  #reconnectTimer?: ReturnType<typeof setTimeout>;
  #reconnectThreshold = 60000;

  #retries = 0;
  #retryScale = 2000;
  maxRetryInterval = 60000;

  endpoint: URL;

  constructor(channel = "events", baseURL = import.meta.url) {
    super();

    console.log(baseURL);

    this.endpoint = new URL(`/websocket/${encodeURI(channel)}`, baseURL);

    this.connect();
  }

  connect() {
    if (this.socket?.readyState <= 2) return;
    this.socket = new WebSocket(this.endpoint);

    this.socket.addEventListener("open", (e) => {
      this.dispatchEvent(new Event("open"));

      this.#retries = 0;

      this.#keepAliveTimer = setInterval(() => {
        this.socket.send("ping");
      }, this.#reconnectThreshold / 2);
    });

    clearTimeout(this.#reconnectTimer);
    this.#reconnectTimer = setTimeout(
      () => {
        console.warn(`No messages for ${this.#reconnectThreshold / 1000}s`);
      },
      Math.min(
        this.maxRetryInterval,
        Math.pow(2, this.#retries) * this.#retryScale,
      ),
    );

    this.socket.addEventListener("close", (e) => {
      this.dispatchEvent(new Event("close"));
      clearInterval(this.#keepAliveTimer);
    });

    this.socket.addEventListener("message", ({ data }) => {
      clearTimeout(this.#reconnectTimer);
      this.#retries = 0;

      switch (true) {
        case data == "pong":
          break;

        case data == "ping":
          this.socket.send("pong");

          this.dispatchEvent(new Event("ping"));
          break;

        default:
          const message = JSON.parse(data);

          if (isReconnectMessage(message)) {
            if (message.timeout) this.#reconnectThreshold = message.timeout;
            if (message.retry) this.#retryScale = message.retry;

            console.info("Updated reconnect settings to", message);
          }

          if (isEventMessage(message)) {
            this.dispatchEvent(new CustomEvent("message", { detail: message }));
          }
      }
    });
  }

  disconnect() {
    if (!this.socket) return;
    this.socket.close();
    clearInterval(this.#keepAliveTimer);
    clearTimeout(this.#reconnectTimer);
  }

  #retry() {
    this.disconnect();
    this.connect();
    this.#retries++;
  }

  get readyState() {
    return this.socket.readyState;
  }
}
