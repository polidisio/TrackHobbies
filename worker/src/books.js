// Funciones puras: construir la URL de Google Books y normalizar la respuesta.
// Los nombres de salida coinciden con `GoogleBookItem` de la app (decodifica sin mapeo).

const FIELDS = "items(id,volumeInfo(title,authors,description,pageCount,imageLinks/thumbnail))";

export function buildUrl(query, maxResults, key) {
  const params = new URLSearchParams({ q: query, maxResults: String(maxResults), fields: FIELDS, key });
  return `https://www.googleapis.com/books/v1/volumes?${params}`;
}

// ISBN-10/13: solo dígitos y X final. Evita que `isbn:` sirva para inyectar otros operadores de búsqueda.
export const isIsbn = (s) => /^(\d{9}[\dXx]|\d{13})$/.test(s);

export function mapBook(vol) {
  const v = vol.volumeInfo ?? {};
  return {
    externalId: vol.id,
    title: v.title ?? "",
    author: (v.authors ?? []).join(", "),
    coverURL: v.imageLinks?.thumbnail?.replace("http://", "https://") ?? null,
    numberOfPages: v.pageCount ?? null,
    summary: v.description ?? null,
  };
}
