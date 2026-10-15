import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";
import { createLobbyChatStore } from "./lobby_chat_store.js";

if (process.env.APPWRITE_CHAT_LIVE_TEST !== "1") {
  console.log("SKIP: set APPWRITE_CHAT_LIVE_TEST=1 to run the private Appwrite persistence probe");
  process.exit(0);
}
const endpoint = "https://sgp.cloud.appwrite.io/v1";
const documentsPath = "/databases/game/collections/matchmaking_queue/documents";
const marker = process.env.CHAT_TEST_DOCUMENT_TYPE || `CHAT_PROBE_${Date.now()}`;
const request = (path, options = {}) => fetch(`${endpoint}${path}`, { ...options,
  headers: { "Content-Type": "application/json", "X-Appwrite-Project": "6a885457002da3f3d47e" },
});
const store = createLobbyChatStore({ request, documentsPath, limit: 3, documentType: marker });
if (process.argv.includes("--read")) {
  const history = await store.history();
  assert.deepEqual(history.map((m) => m.text), ["Private probe 2", "Private probe 3", "Private probe 4"]);
  console.log("PASS: fresh process restored persisted Appwrite messages");
} else {
try {
  for (let i = 0; i < 5; i++) await store.append({ id: `${marker}_${i}`, channel: "lobby", roomId: "",
    userId: "private-storage-probe", userName: "Storage probe", text: `Private probe ${i}`, timestamp: Date.now() + i });
  const { stdout } = await promisify(execFile)(process.execPath, [fileURLToPath(import.meta.url), "--read"], {
    env: { ...process.env, CHAT_TEST_DOCUMENT_TYPE: marker }, timeout: 20000,
  });
  console.log(stdout.trim());
  assert.equal((await store.history()).length, 3);
  console.log("PASS: real Appwrite retention; no public lobby messages sent");
} finally {
  const query = encodeURIComponent(JSON.stringify({ method: "equal", attribute: "userId", values: [marker] }));
  const response = await request(`${documentsPath}?queries[0]=${query}`);
  assert(response.ok, "Could not enumerate the private fixture for cleanup");
  for (const document of (await response.json()).documents) {
    assert(document.userId === marker && document.$id.startsWith("lc_"));
    const removed = await request(`${documentsPath}/${document.$id}`, { method: "DELETE" });
    assert(removed.ok || removed.status === 404, "Could not clean up the private fixture");
  }
}
}
