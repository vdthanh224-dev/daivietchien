export const LOBBY_CHAT_HISTORY_LIMIT = 50;
export const LOBBY_CHAT_DOCUMENT_TYPE = "LOBBY_CHAT_MESSAGE_V1";

// The existing Appwrite collection also holds namespaced leaderboard records.
// A distinct userId keeps chat outside matchmaking queries and room cleanup.
export function createLobbyChatStore({ request, documentsPath, limit = LOBBY_CHAT_HISTORY_LIMIT,
  documentType = LOBBY_CHAT_DOCUMENT_TYPE, onCleanupError = () => {} }) {
  let queue = Promise.resolve();
  const serial = (operation) => {
    const pending = queue.then(operation);
    queue = pending.catch(() => {});
    return pending;
  };
  const call = (path, options = {}) => request(path, { signal: AbortSignal.timeout(5000), ...options });
  const query = (method, attribute, values) => ({ method, ...(attribute ? { attribute } : {}), ...(values ? { values } : {}) });

  async function list(offset = 0) {
    const queries = [query("equal", "userId", [documentType]), query("orderDesc", "timestamp"),
      query("orderDesc", "$sequence"), query("limit", null, [limit]), query("offset", null, [offset])];
    const search = queries.map((value, i) => `queries[${i}]=${encodeURIComponent(JSON.stringify(value))}`).join("&");
    const response = await call(`${documentsPath}?${search}`);
    if (!response?.ok) throw new Error(`Cannot read lobby history (${response?.status || "offline"})`);
    const body = await response.json();
    if (!Array.isArray(body.documents)) throw new Error("Invalid lobby history response");
    return body.documents;
  }

  function decode(document) {
    if (document.userId !== documentType) return null;
    try {
      const value = JSON.parse(document.userName);
      if (typeof value.id !== "string" || !value.id || value.channel !== "lobby" || value.roomId !== ""
        || typeof value.userId !== "string" || typeof value.userName !== "string"
        || typeof value.text !== "string" || !value.text.trim() || Array.from(value.text).length > 280
        || !Number.isFinite(value.timestamp)) return null;
      const normalized = { id: value.id, channel: "lobby", roomId: "", userId: value.userId,
        userName: value.userName, text: value.text, timestamp: value.timestamp };
      // Keep the public profile fields with durable messages when a client
      // sends them, while retaining compatibility with older stored records.
      for (const key of ["title", "profileBg", "level", "rankIndex"]) {
        if (Object.prototype.hasOwnProperty.call(value, key)) normalized[key] = value[key];
      }
      return normalized;
    } catch { return null; }
  }

  async function documentId(id) {
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(id));
    return `lc_${Array.from(new Uint8Array(digest)).map((n) => n.toString(16).padStart(2, "0")).join("").slice(0, 32)}`;
  }

  async function prune() {
    // Re-read the overflow page after each batch: deleting a page shifts offsets.
    for (let page = 0; page < 10; page++) {
      const overflow = await list(limit);
      if (!overflow.length) return;
      for (const document of overflow) {
        if (document.userId !== documentType || !String(document.$id).startsWith("lc_")) continue;
        const response = await call(`${documentsPath}/${encodeURIComponent(document.$id)}`, { method: "DELETE" });
        if (!response?.ok && response?.status !== 404) throw new Error(`Cannot trim lobby history (${response?.status || "offline"})`);
      }
    }
  }

  async function saveMessages(messages, cleanup = true) {
    const normalizedMessages = [];
    for (const message of messages) {
      const normalized = decode({ userId: documentType, userName: JSON.stringify(message) });
      if (!normalized) throw new Error("Invalid lobby message");
      normalizedMessages.push(normalized);
    }
    for (const normalized of normalizedMessages) {
      const id = await documentId(normalized.id);
      const data = { userId: documentType, userName: JSON.stringify(normalized), rankPoints: 0, timestamp: normalized.timestamp };
      const response = await call(documentsPath, { method: "POST", body: JSON.stringify({
        documentId: id, data, permissions: ['read("any")', 'delete("any")'],
      }) });
      if (response?.status === 409) {
        const existing = await call(`${documentsPath}/${id}`);
        if (!existing?.ok || JSON.stringify(decode(await existing.json())) !== JSON.stringify(normalized)) {
          throw new Error("Lobby message id conflicts with another message");
        }
      } else if (!response?.ok) {
        throw new Error(`Cannot save lobby message (${response?.status || "offline"})`);
      }
    }
    // Cleanup once per batch. This avoids one extra Appwrite read for every
    // chat message while preserving the same durable history limit.
    if (cleanup) {
      try { await prune(); } catch (error) { onCleanupError(error); }
    }
    return normalizedMessages;
  }

  return {
    history: () => serial(async () => (await list()).map(decode).filter(Boolean).reverse()),
    append: (message) => serial(async () => (await saveMessages([message]))[0]),
    appendMany: (messages) => serial(async () => saveMessages(messages)),
  };
}
