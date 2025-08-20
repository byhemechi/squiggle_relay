import SquiggleRealtime from "squiggle_realtime";
import { isEventMessage } from "../lib/event";

const socket = new SquiggleRealtime("test");

const output = document.querySelector("#event-list");
if (!output) throw new Error("Output div not found???");

const encoder = new TextEncoder();

socket.addEventListener("message", async (e) => {
  if (!(e instanceof CustomEvent && isEventMessage(e.detail))) return;

  const messageElement = document.createElement(`div`);
  messageElement.setAttribute("data-type", e.detail.event);
  messageElement.id = e.detail.id;
  messageElement.className = "message";
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

    const hue = new Uint16Array(hash)[2];
    messageElement.style.setProperty("--hue", hue.toString());
  }

  if ("startViewTransition" in document) {
    document.startViewTransition(() => {
      messageElement.style.viewTransitionName = `message-${e.detail.id}`;
      output.appendChild(messageElement);
    });
  } else {
    output.appendChild(messageElement);
  }
});
