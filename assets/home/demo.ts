import SquiggleRealtime from "../lib/squiggle_realtime";
import { isEventMessage } from "../lib/event";
import transition from "./transition";

import { message as messageClass, ping } from "./message.module.css";

const template = document.querySelector<HTMLTemplateElement>("#events");

const output = template.content.querySelector<HTMLDivElement>("#event-list");

let didAppendContainer = false;

const encoder = new TextEncoder();

let socket: SquiggleRealtime;

function start(channel: string) {
  socket = new SquiggleRealtime(channel);

  socket.addEventListener("message", async (e) => {
    if (!(e instanceof CustomEvent && isEventMessage(e.detail))) return;

    const messageElement = document.createElement(`div`);
    messageElement.setAttribute("data-type", e.detail.event);
    messageElement.id = e.detail.id;
    messageElement.className = messageClass;

    messageElement.style.setProperty(
      "view-transition-name",
      `message-${e.detail.id}`,
    );

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
      if (!didAppendContainer) {
        document.body.appendChild(template.content);
        didAppendContainer = true;

        if (isPolyfilled)
          document
            .querySelector("article")
            .animate([{ transform: "translateX(256px)" }, {}], {
              duration: 500,
              easing: "ease",
            });
      }
      output.appendChild(messageElement);
    });
  });

  socket.addEventListener("ping", () => {
    const pingEl = document.createElement("div");
    pingEl.className = ping;
    pingEl.textContent = "Keepalive message";
    pingEl.style.setProperty("view-transition-name", `ping-${Date.now()}`);
    transition(() => output.appendChild(pingEl));
  });
}

const buttonContainer =
  template.content.querySelector<HTMLDivElement>("#channel_selector");

import("squiggle_realtime/client_data").then(({ activeChannels }) => {
  let channelButtons = new Map<string, HTMLButtonElement>();

  for (const channel of activeChannels) {
    const button = document.createElement("button");
    button.textContent = channel;
    channelButtons.set(channel, button);

    button.addEventListener("click", () => {
      socket.disconnect();
      setActiveChannel(channel);
    });

    buttonContainer.appendChild(button);
  }
  const [defaultChannel] = activeChannels;

  function setActiveChannel(channel: string) {
    selected = channel;
    start(channel);

    transition(() => {
      for (const i of channelButtons.values()) {
        i.classList.remove("active");
      }
      channelButtons.get(channel)?.classList.add("active");
    });
  }

  let selected = activeChannels.has("test") ? "test" : defaultChannel;

  setActiveChannel(selected);
});
