# Diario de desarrollo · TrackHobbies

Registro cronológico de lo que se hace cada día: qué, por qué y qué queda. Una entrada nueva por día, la más reciente arriba.
Arquitectura viva en `Docs/architecture/architecture.html` (dashboard) y `architecture.json` (datos). Analytics en `Docs/ANALYTICS.md`.

---

## 2026-10-01 (jueves)

**Resumen:** 19 commits. De «app local con búsqueda frágil» a app localizada y accesible, con libros y juegos detrás de un Worker, sincronización CloudKit en producción, analytics opt-in con dashboard y seguimiento de páginas corregido.

### 1. Endurecimiento de la base (09:38–13:14)
| Commit | Qué |
|---|---|
| `35288f5` | Código muerto fuera y archivos generados sin seguimiento |
| `0b8f865` | Esquema SwiftData versionado; si el almacén falla la app arranca en memoria y avisa, sin crash |
| `58fa43f` | Búsqueda asíncrona con debounce, cancelación, errores visibles (`SearchError`) y cliente de IGDB |
| `e03c2d7` | Worker de Cloudflare como proxy de IGDB (claves fuera de la app) |
| `3c5241e` / `3537350` | Docs corregidas y proyecto regenerado con XcodeGen |
| `72cb1cd`, `c5507df` | Confirmación antes de borrar y antes de cambios que borran datos del usuario |
| `2ff23b7` | Accesibilidad: VoiceOver y Dynamic Type |
| `c9d566e` | Localización es/en con `Localizable.xcstrings` |

### 2. Herramientas
- **MobileBuildMCP** no conectaba (`CONNECTION_CLOSED`): caché corrupta de npx (`fast-uri` incompleto). Se borró esa entrada de `~/.npm/_npx` y arrancó.
- Con PostHog añadido, la build incremental del MCP fallaba al enlazar (x86_64 frente a arm64). Se fijó `ARCHS=arm64` en los defaults de la sesión del MCP (no en el repo).
- Tests: `@testable import` no compilaba porque `ENABLE_TESTABILITY` venía en NO también en Debug. Activado solo para Debug en `project.yml`.

### 3. Búsqueda de libros: del 429 al Worker
1. Síntoma: «Demasiadas búsquedas seguidas». No era el debounce: Google Books respondía `429 Queries per day` por usar la cuota anónima compartida.
2. `b353b78`: clave de API propia en `Secrets.xcconfig` → `Info.plist`.
3. Pregunta de límites: solo los juegos pasaban por el Worker; la clave de Google iba en el binario y la cuota (~1.000/día) es de todos los usuarios juntos.
4. `c57b7a9`: libros movidos al Worker (`/books/search`, `/books/isbn`), clave como secreto, caché de 24 h, validación de ISBN, helper común `URLSession.worker` y 9 tests del Worker. La clave salió del binario.
5. Hallazgo: las consultas `isbn:` de Google Books devuelven 0 resultados incluso directas (afecta al enriquecimiento de Goodreads).

### 4. Sincronización CloudKit
- `1ebf761`: modelos compatibles con CloudKit (sin `.unique`, valores por defecto, relación inversa), `SchemaV1` congelado + `SchemaV2` con migración ligera, `cloudKitDatabase: .private("iCloud.com.trackhobbies.app")`, modo `remote-notification`, `DEVELOPMENT_TEAM` desde `Secrets.xcconfig`. Datos del simulador conservados tras migrar.
- `70b53a9`: faltaba `aps-environment` en los entitlements (CloudKit avisa de cambios remotos por push silencioso). Verificado firmando para dispositivo.
- `b166107`: `SyncMonitor` + `SyncStatusView` en Estadísticas (cuenta de iCloud, última sincronización, error) y evento `sync_error`.
- **Incidente:** `CKErrorDomain 2` con `12` y `22`, «Cannot create new type CD_ResourceEntity in production schema». Las builds de TestFlight usan **Production** y el esquema no estaba desplegado. Resolución: crear el esquema en Development desde una build Debug y desplegarlo a Production desde el CloudKit Console.
- Después: iPhone→iPad llegaba y iPad→iPhone solo al reabrir. Se descartó el estado viejo por cambio de entorno (la reinstalación limpia ya estaba hecha). El usuario confirma al final que funciona; **la causa exacta de ese último síntoma no se aisló**.

### 5. Seguimiento por páginas (`d80fb09`)
- Bug: con la página actual ya puesta, teclear el total (`3`, `35`, `350`) marcaba el libro como completado en el primer dígito.
- Arreglo: total de solo lectura con editor explícito (valida 1…10 000 y que no sea menor que la página actual), página limitada al total, completado solo al avanzar la página, botón «Marcar como completado» si ya estaba en la última.
- Reglas puras en `Utils/PageTracking.swift` + 3 tests XCTest.

### 6. Analytics con PostHog
- `1008fe9`: PostHog EU opt-in (hoja de consentimiento + interruptor en Estadísticas), sin identify ni GeoIP, `PrivacyInfo.xcprivacy`, doc en `Docs/ANALYTICS.md`. Mismo patrón que DrinkTrack y SyncSalud (consultados en local, solo lectura).
- Eventos: `resource_added`, `resource_deleted`, `import_done`, `export_started`, `search_error`, `$screen`. Después `67b9beb`: `status_changed` (con `days_to_complete`) y `resource_edited`.
- Dashboard existente «TrackHobbies - App iOS» (id 989027): +9 insights (completados por semana, días hasta completar, transiciones, eliminados, editados, ciclo de vida, embudo añadir→completar, errores de búsqueda, cuota agotada) y **1 alerta** diaria si `rateLimited` > 20/día.
- Se comprobó en PostHog que llegaban `$screen`, `resource_added` y los eventos de ciclo de vida.

### 7. Icono (`259e815`)
Primer diseño descartado (marco redondeado propio, «PLAY» duplicado, cuarto cuadrante «CREATE» sin sentido). El segundo, a sangre completa y sin texto, instalado como `AppIcon.png` de 1024 px (sin alfa).

### 8. Documentación y dashboard de arquitectura
`Docs/architecture/` (HTML autocontenido + JSON + `build.py`), este diario, `lessons.md` y actualización de `CLAUDE.md`, `AGENTS.md` y `README.md`.

### Decisiones tomadas
- Todas las claves de terceros viven en el Worker; la app solo lleva un token de app.
- Series sigue directo contra TVMaze (sin clave y el límite es por IP de cada usuario).
- Analytics: solo categorías y contadores; nunca títulos, notas, reseñas ni puntuaciones.
- El esquema de Production solo crece: congelar versión + `MigrationStage` antes de tocar modelos.
- Un único dashboard de PostHog por app; las insights nuevas se añaden al existente.

### Estado al cierre
- `main` publicado con todo lo de hoy, incluido el ajuste de `SyncMonitor` (error interno distinto de `batchRequestFailed`) y esta documentación.
- **Fuera de git a propósito:** `Localizable.xcstrings` (Xcode lo reordena al compilar, sin cambios de contenido), `project.pbxproj` y el esquema (Xcode 27 reescribe el formato; XcodeGen los regenera) y `xcshareddata/` (Package.resolved).

### Para mañana
- [ ] Decidir si versionar `Package.resolved` y si ignorar los reordenados de `Localizable.xcstrings`.
- [ ] Eventos `sync_ok` para medir latencia de la sincronización y ver el lado receptor sin capturas.
- [ ] Bundle id propio para Debug (`com.trackhobbies.app.dev`) y no volver a mezclar entornos en un mismo dispositivo.
- [ ] Decidir qué hacer con `PendingItemEntity` (usarla o retirarla) **antes** de desplegar más esquema.
- [ ] Buscar páginas para libros añadidos a mano (ruta nueva del Worker, elegir edición).
- [ ] Mirar las insights de PostHog con datos reales de la build nueva.
- [ ] Revisar si el enriquecimiento por ISBN de Goodreads sirve de algo o consultar por título y autor.
- [ ] Exportación a Notion (planeada).
