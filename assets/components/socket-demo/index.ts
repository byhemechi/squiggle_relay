import "./demo.css";
import SquiggleRealtime from "squiggle_realtime";
import { isEventMessage } from "squiggle_realtime/event";
import transition from "./transition";
import { activeChannels } from "client_data";

import { message as messageClass, ping, outdated } from "./message.module.css";

const encoder = new TextEncoder();

export default class Demo extends HTMLElement {
  #socket: SquiggleRealtime;
  #internals = this.attachInternals();

  #channelButtons = new Map<string, HTMLButtonElement>();

  #output =
    this.#internals.shadowRoot.querySelector<HTMLDivElement>(".event_list");

  buttonContainer =
    this.#internals.shadowRoot.querySelector<HTMLDivElement>(
      ".channel_selector",
    );

  #joinTimeout: ReturnType<typeof setTimeout>;

  connectedCallback() {
    const defaultChannel = activeChannels.has("test")
      ? "test"
      : activeChannels[0];
    transition(() => {
      for (const channel of activeChannels) {
        const button = document.createElement("button");
        button.textContent = channel;
        this.#channelButtons.set(channel, button);

        button.addEventListener("click", () => {
          this.#socket.disconnect();
          this.setActiveChannel(channel);
        });

        this.buttonContainer.appendChild(button);
      }
      this.#channelButtons.get(defaultChannel)?.classList.add("active");
    });

    this.#joinTimeout = setTimeout(() => {
      this.setActiveChannel(defaultChannel);
      this.#output.innerHTML = "";
    }, 500);
  }

  disconnectedCallback() {
    clearTimeout(this.#joinTimeout);
    this.#socket.disconnect();
  }

  start(channel: string) {
    this.#socket = new SquiggleRealtime(channel);

    this.#socket.addEventListener("open", () => {
      transition(() => {
        for (const message of this.#output.getElementsByClassName(
          messageClass,
        )) {
          console.log(message);
          message.classList.add(outdated);
        }
      });
    });

    this.#socket.addEventListener("message", async (e) => {
      if (!(e instanceof CustomEvent && isEventMessage(e.detail))) return;

      const messageElement = document.createElement(`div`);
      messageElement.setAttribute("data-type", e.detail.event);
      messageElement.id = e.detail.id;
      messageElement.className = messageClass;

      if (e.detail.event == "message" && typeof e.detail.data === "string") {
        const bodyElement = document.createElement("p");
        bodyElement.textContent = e.detail.data;
        messageElement.appendChild(bodyElement);
      } else {
        const bodyElement = document.createElement("pre");
        bodyElement.textContent = JSON.stringify(e.detail.data, null, 2);
        messageElement.appendChild(bodyElement);
      }

      if (window.crypto?.subtle) {
        const hash = await crypto.subtle.digest(
          "sha-256",
          encoder.encode(e.detail.event),
        );

        const hue = (new Uint8Array(hash)[14] / 0xff) * 360;
        messageElement.style.setProperty("--hue", hue.toString());

        let currentHue = Number(
          getComputedStyle(document.documentElement).getPropertyValue("--hue"),
        );

        [, currentHue] = [currentHue - 360, currentHue, currentHue + 360]
          .map((i, n) => [Math.abs(i - hue), i, n])
          .sort(([a], [b]) => a - b)[0];

        document.documentElement.style.setProperty("--hue", hue.toString());
        document.documentElement.animate(
          [
            {
              "--hue": currentHue,
            },
            { "--hue": hue },
          ],
          { easing: "ease", fill: "both", duration: 500 },
        );
      }

      transition((isPolyfilled) => {
        this.#output.appendChild(messageElement);
      });
    });

    this.#socket.addEventListener("ping", () => {
      const pingEl = document.createElement("div");
      pingEl.className = ping;
      pingEl.textContent = "Keepalive message";
      pingEl.style.setProperty("view-transition-name", `ping-${Date.now()}`);
      transition(() => this.#output.appendChild(pingEl));
    });
  }

  setActiveChannel(channel: string) {
    this.start(channel);

    transition(() => {
      for (const i of this.#channelButtons.values()) {
        i.classList.remove("active");
      }
      this.#channelButtons.get(channel)?.classList.add("active");
    });
  }
}
