# Analytics (PostHog)

Mismo patrón que DrinkTrack/MyBarTrack y Synctrackers: PostHog Cloud EU, **opt-in**, off por defecto.

- Proyecto PostHog compartido; todos los eventos llevan `app = "trackhobbies"` (filtra por ella).
- Sin `identify`, sin autocapture, sin session replay, `$geoip_disable = true`.
- Activar "Discard client IP data" en el proyecto PostHog (ajuste manual, no controlable desde el SDK).
- Consentimiento: sheet en primer arranque (`AnalyticsConsentView`) + toggle "Compartir uso anónimo" al final de Estadísticas.

## Setup local
1. `Config/Secrets.xcconfig` (gitignored; plantilla en `Config/Secrets.example.xcconfig`).
2. `POSTHOG_API_KEY` = **Project token `phc_…`** (nunca `phx_`/`phs_`). `POSTHOG_HOST = eu.i.posthog.com` (sin `https://`).
3. `xcodegen generate`.

## Regla
Solo contadores, booleanos y categorías. **Nunca** títulos, autores, notas, reseñas, puntuaciones ni textos de búsqueda.

## Eventos
| Evento | Props | Origen |
|---|---|---|
| `resource_added` | `type` (`book`/`series`/`game`), `source` (`search`/`wishlist`/`manual`) | ViewModels `add*` |
| `resource_deleted` | `type` | `ConfirmDelete` |
| `status_changed` | `type`, `from`, `to` (valores de `ProgressStatus`), `days_to_complete` (solo si `to = completed` y hay fecha de inicio) | `ResourceDetailView` (`onChange` del estado: selector y completado automático) |
| `resource_edited` | `type` — una vez al salir del detalle si algo cambió; sin campo ni valor | `ResourceDetailView` (`onDisappear`) |
| `import_done` | `source` (`goodreads` / `trackhobbies` = CSV propio / `backup` = copia JSON), `count` (añadidos), `enriched` (solo Goodreads) | `BooksViewModel.importBooks`, `CSVImporter.insert` |
| `export_started` | `format` (`csv` / `json`; los eventos anteriores a 2026-10-02 no lo traen) (ShareLink no informa de finalización) | `ExportCSVButton`, `BackupView` |
| `search_error` | `reason` (caso de `SearchError`, nunca la query) | `Searchable.performSearch` |
| `$screen` | `$screen_name` (`books`, `series`, `games`, `stats`) | `ContentView` |
| lifecycle | SDK | `captureApplicationLifecycleEvents` |

## Privacidad de la App Store
`PrivacyInfo.xcprivacy`: Product Interaction + Device ID, finalidad Analytics, sin tracking. Reflejar lo mismo en App Store Connect.

## Si no aparecen eventos
Ver `SyncSalud/Docs/ANALYTICS.md` (key ≠ `phc_`, región, consentimiento, build antigua, lote ~30 s).

## Sincronización iCloud (diagnóstico)
| Evento | Props | Origen |
|---|---|---|
| `sync_error` | `kind` (`setup`/`import`/`export`), `domain`, `code`, `inner_codes` (códigos de los errores internos de un partialFailure; nunca el texto) | `SyncMonitor` |
| `sync_ok` | `kind` (`setup`/`import`/`export`), `duration_ms` (inicio→fin del evento de CloudKit; `import` = lado receptor) | `SyncMonitor` |

## Dashboard y builds de prueba

Dashboard «TrackHobbies - App iOS» (id 989027, proyecto 289000, EU). El proyecto de PostHog es **compartido con otras apps**, por eso cada insight filtra `$app_name = TrackHobbies`.

Las builds Debug usan el bundle id `com.trackhobbies.app.dev` y llevan el mismo `$app_name`: el **filtro del dashboard** `$app_namespace = com.trackhobbies.app` las excluye de todos los tiles. Para ver también las de prueba, quitar ese filtro en el dashboard o consultar con `$app_namespace` explícito.

Insights de sincronización e importación (2026-10-02): «Sincronización: correctas frente a errores», «Latencia de sync: lado receptor (import)», «Errores de sincronización por código», «Importaciones por origen» y «Exportaciones por formato».

