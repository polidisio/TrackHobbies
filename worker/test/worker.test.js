import test from "node:test";
import assert from "node:assert/strict";
import worker from "../src/index.js";
import { buildQuery, mapGame } from "../src/igdb.js";

const env = { TWITCH_CLIENT_ID: "id", TWITCH_CLIENT_SECRET: "secret", APP_TOKEN: "tok" };
const req = (path, token = "tok") =>
  new Request(`https://w.test${path}`, { headers: token ? { "X-App-Token": token } : {} });

test("buildQuery no deja escapar comillas del usuario", () => {
  const q = buildQuery('zelda"; fields *; where id > 0; "');
  assert.equal(q.split('"').length - 1, 2); // solo las comillas de apertura/cierre del search
  assert.ok(q.startsWith('search "zelda'));
});

test("mapGame normaliza", () => {
  assert.deepEqual(
    mapGame({ id: 7, name: "Hades", first_release_date: 1600000000, genres: [{ name: "Roguelike" }], cover: { image_id: "co1" } }),
    { id: "7", title: "Hades", imageURL: "https://images.igdb.com/igdb/image/upload/t_cover_big/co1.jpg", released: "2020-09-13", genres: ["Roguelike"] },
  );
  assert.equal(mapGame({ id: 1, name: "X" }).imageURL, null);
});

test("rechaza sin token de app y no llama a IGDB", async () => {
  globalThis.fetch = () => assert.fail("no debe llamar upstream");
  assert.equal((await worker.fetch(req("/games/search?q=zelda", null), env)).status, 401);
  assert.equal((await worker.fetch(req("/games/search?q=zelda", "mal"), env)).status, 401);
});

test("query corta devuelve vacío; ruta desconocida 404", async () => {
  globalThis.fetch = () => assert.fail("no debe llamar upstream");
  assert.deepEqual(await (await worker.fetch(req("/games/search?q=a"), env)).json(), { results: [] });
  assert.equal((await worker.fetch(req("/otra"), env)).status, 404);
});

test("búsqueda ok, reintenta con token nuevo ante 401 y mapea 429", async () => {
  let igdbCalls = 0;
  globalThis.fetch = async (url) => {
    if (String(url).startsWith("https://id.twitch.tv")) {
      return Response.json({ access_token: `t${igdbCalls}`, expires_in: 3600 });
    }
    igdbCalls++;
    if (igdbCalls === 1) return new Response(null, { status: 401 });
    return Response.json([{ id: 1, name: "Hades" }]);
  };
  const ok = await worker.fetch(req("/games/search?q=hades"), env, { waitUntil() {} });
  assert.equal(ok.status, 200);
  assert.equal((await ok.json()).results[0].title, "Hades");
  assert.equal(igdbCalls, 2);

  globalThis.fetch = async (url) =>
    String(url).startsWith("https://id.twitch.tv")
      ? Response.json({ access_token: "x", expires_in: 3600 })
      : new Response(null, { status: 429 });
  assert.equal((await worker.fetch(req("/games/search?q=mario"), env, { waitUntil() {} })).status, 429);
});

// --- libros ---
import { buildUrl, isIsbn, mapBook } from "../src/books.js";
const benv = { ...env, GOOGLE_BOOKS_API_KEY: "AIzaTEST" };

test("mapBook normaliza y fuerza https", () => {
  assert.deepEqual(
    mapBook({ id: "b1", volumeInfo: { title: "Dune", authors: ["Frank Herbert", "X"], pageCount: 412, description: "d", imageLinks: { thumbnail: "http://img/x" } } }),
    { externalId: "b1", title: "Dune", author: "Frank Herbert, X", coverURL: "https://img/x", numberOfPages: 412, summary: "d" },
  );
  assert.deepEqual(mapBook({ id: "b2", volumeInfo: {} }), { externalId: "b2", title: "", author: "", coverURL: null, numberOfPages: null, summary: null });
});

test("isIsbn solo acepta ISBN-10/13", () => {
  assert.ok(isIsbn("9780441172719") && isIsbn("044117271X"));
  assert.ok(!isIsbn("dune") && !isIsbn("978044117271") && !isIsbn("isbn:1 OR intitle:x"));
});

test("buildUrl codifica la consulta y lleva la clave", () => {
  const u = new URL(buildUrl("a&key=evil", 20, "K"));
  assert.equal(u.searchParams.get("q"), "a&key=evil");
  assert.equal(u.searchParams.get("key"), "K");
});

test("libros: exige token, busca, mapea y propaga 429", async () => {
  globalThis.fetch = () => assert.fail("no debe llamar upstream");
  assert.equal((await worker.fetch(req("/books/search?q=dune", null), benv)).status, 401);
  assert.deepEqual(await (await worker.fetch(req("/books/isbn?isbn=malo"), benv)).json(), { results: [] });

  let called;
  globalThis.fetch = async (url) => {
    called = String(url);
    return Response.json({ items: [{ id: "b1", volumeInfo: { title: "Dune" } }] });
  };
  const ok = await worker.fetch(req("/books/search?q=dune"), benv, { waitUntil() {} });
  assert.equal((await ok.json()).results[0].title, "Dune");
  assert.ok(called.includes("key=AIzaTEST"));
  const isbn = await worker.fetch(req("/books/isbn?isbn=9780441172719"), benv, { waitUntil() {} });
  assert.equal((await isbn.json()).results.length, 1);
  assert.ok(called.includes("isbn%3A9780441172719"));

  globalThis.fetch = async () => new Response(null, { status: 429 });
  assert.equal((await worker.fetch(req("/books/search?q=otro"), benv, { waitUntil() {} })).status, 429);
});
