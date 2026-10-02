# Lecciones aprendidas · TrackHobbies

Qué salió mal, por qué y cómo evitarlo (ver `CLAUDE.md` → Self-Improvement). Una línea de contexto por lección; el detalle está en `Docs/DIARIO.md`.

## 2026-10-01

1. **CloudKit: TestFlight usa Production, Xcode usa Development.**
   Síntoma: `CKErrorDomain 2` → `12` + `22`, «Cannot create new type … in production schema».
   Evitar: antes de subir a TestFlight, crear el esquema con una build Debug y desplegarlo a Production desde el CloudKit Console. No alternar un mismo dispositivo entre Debug y TestFlight.
2. **CloudKit necesita `aps-environment`.** Sin él no llegan los avisos de cambios remotos (la sync «va a medias»). Comprobar con `codesign -d --entitlements :- <app>` en una build de dispositivo.
3. **`partialFailure` (CKError 2) esconde la causa.** Mirar `CKPartialErrorsByItemIDKey` y saltarse el `22 batchRequestFailed` ("atomic failure"): el culpable es el otro. `SyncMonitor` ya lo muestra.
4. **No guardar en el modelo a cada tecla.** Los campos de página actual y total escribían en cada pulsación y marcaban «completado» con totales a medio teclear. Validar y aplicar con una acción explícita; poner la regla en una función pura con test (`PageTracking`).
5. **Las claves de terceros no van en el binario.** La API key de Google Books en el `Info.plist` es extraíble y su cuota diaria es de todos los usuarios. Pasarla por el Worker (secreto + caché).
6. **Escanear secretos antes de cada commit.** Una plantilla `*.example` terminó con el Team ID real; se detectó antes de subir. Comparar los valores de `Config/Secrets.xcconfig` con los archivos a subir.
7. **`Localizable.xcstrings` se reordena solo al compilar.** Al editarlo por script, conservar el formato exacto de Xcode (separador ` : `, objetos vacíos con línea en blanco) y no commitear solo el reordenado.
8. **`ENABLE_TESTABILITY` venía en NO también en Debug** (XcodeGen sin presets): `@testable import` no compilaba. Fijado en `project.yml`.
9. **MobileBuildMCP:** `ARCHS=arm64` en los defaults de la sesión cuando se añaden paquetes SPM; si `npx` falla con `Cannot find module`, borrar su entrada de `~/.npm/_npx`.
10. **Las cuotas gratis son de memoria.** Verificarlas antes de depender de ellas (Google Books ~1.000/día, IGDB ~4/s, Workers 100.000/día) y vigilar `search_error` con `rateLimited` (alerta en PostHog).
11. **Los operadores de Google Books no funcionan con esta clave.** `intitle:`, `inauthor:` e `isbn:` devuelven 0 resultados; el texto plano sí. Probar la consulta real con `curl` contra el Worker antes de darla por buena (`BookMatch.query` ya usa texto plano). Además Google da 502/503 sueltos: `GoogleBooksService.search` reintenta una vez.
12. **Probar en el simulador iOS 27, no en el iPhone 17 Pro (iOS 26.2):** `xcodebuild test` y `simctl install` se cuelgan allí. El flujo `ui-automation` de MobileBuildMCP se activa en `.mobilebuildmcp/config.yaml` y exige reconectar el MCP (`/mcp`).
13. **El autocorrector estropea títulos y autores** («Dune» → «Dime»). `.autocorrectionDisabled()` en los campos de nombres propios.
14. **No partir un CSV por líneas.** Las reseñas de Goodreads llevan saltos de línea y comillas dentro del campo; usar `CSVImporter.parseRows` (RFC 4180). En Goodreads, `My Rating` 0 = sin puntuar (→ `nil`), el ISBN viene como `="…"` y los saltos de la reseña como `<br/>`.

