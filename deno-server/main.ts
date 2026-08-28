// Keep the TypeScript entrypoint as a compatibility shim. The canonical
// JavaScript server owns the REST, WebSocket, and authoritative tick loop.
import "./server.js";
