import { buildQuery, mapGame } from "./igdb.js";
import { buildUrl, isIsbn, mapBook } from "./books.js";

const CACHE_SECONDS = 24 * 60 * 60;

// Token de Twitch en memoria del isolate; si el isolate se recicla se pide otro (barato).
let token = { value: null, expires: 0 };

async function getToken(env, force = false) {
  if (!force && token.value && Date.now() < token.expires) return token.value;
  const res = await fetch(
    "https://id.twitch.tv/oauth2/token?" +
      new URLSearchParams({
        client_id: env.TWITCH_CLIENT_ID,
        client_secret: env.TWITCH_CLIENT_SECRET,
        grant_type: "client_credentials",
      }),
    { method: "POST" },
  );
  if (!res.ok) throw new Response(null, { status: 502 });
  const body = await res.json();
  token = { value: body.access_token, expires: Date.now() + (body.expires_in - 300) * 1000 };
  return token.value;
}

async function igdbSearch(env, q, retry = true) {
  const res = await fetch("https://api.igdb.com/v4/games", {
    method: "POST",
    headers: {
      "Client-ID": env.TWITCH_CLIENT_ID,
      Authorization: `Bearer ${await getToken(env, !retry)}`,
      "Content-Type": "text/plain",
    },
    body: buildQuery(q),
  });
  if (res.status === 401 && retry) return igdbSearch(env, q, false); // token revocado/caducado
  if (res.status === 429) throw new Response(null, { status: 429 });
  if (!res.ok) throw new Response(null, { status: 502 });
  return (await res.json()).map(mapGame);
}

const json = (data, status = 200, headers = {}) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...headers },
  });

// Cache por (ruta, consulta): una búsqueda repetida no gasta cuota del upstream.
async function cached(ctx, key, produce) {
  const cache = globalThis.caches?.default;
  const cacheKey = new Request(`https://cache.trackhobbies.invalid/${key}`);
  const hit = await cache?.match(cacheKey);
  if (hit) return hit;
  try {
    const response = json(await produce(), 200, { "Cache-Control": `public, max-age=${CACHE_SECONDS}` });
    if (cache) ctx.waitUntil(cache.put(cacheKey, response.clone()));
    return response;
  } catch (e) {
    if (e instanceof Response) return json({ error: "upstream" }, e.status);
    throw e;
  }
}

async function booksFetch(env, query, maxResults) {
  const res = await fetch(buildUrl(query, maxResults, env.GOOGLE_BOOKS_API_KEY));
  if (res.status === 429) throw new Response(null, { status: 429 });
  if (!res.ok) throw new Response(null, { status: 502 });
  return ((await res.json()).items ?? []).map(mapBook);
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const route = url.pathname;
    if (request.method !== "GET" || !["/games/search", "/books/search", "/books/isbn"].includes(route)) {
      return json({ error: "not found" }, 404);
    }
    if (!env.APP_TOKEN || request.headers.get("X-App-Token") !== env.APP_TOKEN) return json({ error: "unauthorized" }, 401);

    // ponytail: sin rate limit propio; añadir el binding `ratelimit` de Cloudflare si hay abuso.
    if (route === "/books/isbn") {
      const isbn = (url.searchParams.get("isbn") ?? "").trim();
      if (!isIsbn(isbn)) return json({ results: [] });
      return cached(ctx, `books-isbn?isbn=${isbn.toUpperCase()}`, async () => ({
        results: await booksFetch(env, `isbn:${isbn}`, 1),
      }));
    }

    const q = (url.searchParams.get("q") ?? "").trim().slice(0, 100);
    if (q.length < 2) return json({ results: [] });
    const key = `${route.slice(1).replace("/", "-")}?q=${encodeURIComponent(q.toLowerCase())}`;
    return cached(ctx, key, async () => ({
      results: route === "/books/search" ? await booksFetch(env, q, 20) : await igdbSearch(env, q),
    }));
  },
};
