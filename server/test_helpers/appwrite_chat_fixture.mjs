export function createAppwriteChatFixture() {
  const documents = new Map();
  let sequence = 0;
  const fixture = { documents, failReads: false, failWrites: false, failDeletes: false };
  fixture.request = async (path, options = {}) => {
    const url = new URL(path, "https://appwrite.test");
    const id = url.pathname.match(/\/documents\/([^/]+)$/)?.[1];
    const method = options.method || "GET";
    const response = (body, status = 200) => new Response(JSON.stringify(body), { status });
    if (method === "POST") {
      if (fixture.failWrites) return response({}, 503);
      const { documentId, data, permissions } = JSON.parse(options.body);
      if (documents.has(documentId)) return response({}, 409);
      const doc = { ...data, $id: documentId, $sequence: ++sequence, $permissions: permissions };
      documents.set(documentId, doc);
      return response(doc, 201);
    }
    if (method === "DELETE") {
      if (fixture.failDeletes) return response({}, 503);
      if (!documents.delete(id)) return response({}, 404);
      return new Response(null, { status: 204 });
    }
    if (fixture.failReads) return response({}, 503);
    if (id) return response(documents.get(id) || {}, documents.has(id) ? 200 : 404);
    let rows = [...documents.values()];
    const queries = [...url.searchParams].filter(([key]) => key.startsWith("queries[")).map(([, value]) => JSON.parse(value));
    const ordering = queries.filter((q) => q.method === "orderDesc");
    for (const q of queries) if (q.method === "equal") rows = rows.filter((doc) => q.values.includes(doc[q.attribute]));
    rows.sort((a, b) => {
      for (const q of ordering) { const diff = b[q.attribute] - a[q.attribute]; if (diff) return diff; }
      return 0;
    });
    const total = rows.length;
    const offset = queries.find((q) => q.method === "offset")?.values[0] || 0;
    const limit = queries.find((q) => q.method === "limit")?.values[0] || 25;
    return response({ total, documents: rows.slice(offset, offset + limit) });
  };
  return fixture;
}
