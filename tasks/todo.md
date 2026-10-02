# Pendientes · TrackHobbies

Actualizado 2026-10-02. Orden por valor/riesgo.

## En curso
- [x] 1. `PendingItemEntity`: decisión → **mantener** (ver abajo).
- [x] 2. Tests: el problema era el runtime del simulador (iPhone 17 Pro = iOS 26.2 cuelga). Usar iPhone 18 Pro (iOS 27) con `test_sim`. 11 tests pasan.
- [x] 3. Bundle id propio para Debug (`com.trackhobbies.app.dev`) en `project.yml`. Falta: primera build de dispositivo para que Xcode registre el App ID con iCloud; en dispositivos que tenían Debug, borrar la app vieja.

## Para retomar
- [x] 4. Evento `sync_ok` (kind + duration_ms) en `SyncMonitor`. Insight en el dashboard de PostHog creado (ver 10).
- [x] 5. Páginas para libros a mano: botón «Buscar páginas» en el detalle. Probado con el MCP y el Worker real (Hyperion → 642 págs. + portada).
- [x] 6. Enriquecimiento Goodreads por título + autor (`BookMatch`).
- [x] 7. Backup JSON completo (Estadísticas → Copia de seguridad): exporta/restaura todos los campos y el `id`; solo añade.
- [x] 8. Git: `Package.resolved` versionado y `project.pbxproj` regenerado (el de git no tenía los archivos nuevos). `Localizable.xcstrings`: NO commitear la copia de trabajo (Xcode la reordena y marca como `stale` cadenas en uso); añadir entradas sobre la versión de HEAD (lección 7).
- [x] 9. Aviso de importación (añadidos/omitidos) en CSV propio, Goodreads y copia JSON; errores visibles en vez de `print`.
- [x] 10. PostHog: 5 insights nuevos (sync ok/error, latencia import, errores por código, importaciones por origen, exportaciones por formato) y filtro de dashboard `$app_namespace` que excluye `.dev`. Datos reales verificados.
- Producto (opcional): widget «ahora leyendo/viendo», recordatorios de progreso, estadísticas por año.

## Decisión `PendingItemEntity`
Código muerto: nadie lo crea ni lo lee. Pero `CD_PendingItemEntity` ya está en el esquema **Production** de CloudKit (no se pueden borrar tipos) y quitarlo exige `SchemaV3` + `MigrationStage` sobre datos reales de iPhone/iPad, sin ningún beneficio funcional.
Se mantiene tal cual. Si algún día se usa (p. ej. recordatorios), ya está desplegado. Retirarlo solo si molesta, junto a otro cambio de esquema.
