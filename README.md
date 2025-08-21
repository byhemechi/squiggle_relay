# Squiggle Event Relay

## What is this?

[Squiggle](https://squiggle.com.au) has a server-sent events endpoint for things like match scores. Unfortunately, the client limit is low and 429 errors are common.

I've made this relay to allow apps that benefit from the real-time data but don't rely on it to access it without eating up the connection limit for everyone who actually needs it

The server should be able to handle hundreds if not thousands of concurrent connections with no issue. There is no rate limit for now, that may change if people abuse this. Please don't retry immediately, use exponential back off.

Connections will be culled at the server side if it receives no data for a minute. You can send a "ping" message to make sure this doesn't happen.

I have included a simple JavaScript library that connects and subscribes to the events endpoint. It includes reconnects and keepalives.

```javascript
import SquiggleRealtime from "http://localhost:4000/lib/squiggle_realtime.js";

const socket = new SquiggleRealtime("test");

socket.addEventListener("message", ({ detail }) => {
    console.log("Received message", detail)
});
```
