// Funciones puras: construir la query Apicalypse y normalizar la respuesta de IGDB.

export function buildQuery(q) {
  // Las comillas y backslashes rompen la sintaxis Apicalypse (y permitirían inyectar cláusulas).
  const safe = q.replace(/[\\"]/g, " ").trim();
  return `search "${safe}"; fields name,first_release_date,genres.name,cover.image_id; where version_parent = null; limit 20;`;
}

export function mapGame(g) {
  return {
    id: String(g.id),
    title: g.name ?? "",
    imageURL: g.cover?.image_id
      ? `https://images.igdb.com/igdb/image/upload/t_cover_big/${g.cover.image_id}.jpg`
      : null,
    released: g.first_release_date
      ? new Date(g.first_release_date * 1000).toISOString().slice(0, 10)
      : null,
    genres: (g.genres ?? []).map((x) => x.name),
  };
}
