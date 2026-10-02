# Pendientes · TrackHobbies

Actualizado 2026-10-02. Orden por valor/riesgo.

## En curso
- [x] 1. `PendingItemEntity`: decisión → **mantener** (ver abajo).
- [ ] 2. Arreglar `xcodebuild test`. Hecho: `EXCLUDED_ARCHS[sdk=iphonesimulator*]=x86_64` en `project.yml` (el enlazado con PostHog fallaba sin `ARCHS=arm64`). **Sigue colgado**: compila, pero `simctl install` en el simulador iPhone 17 Pro (runtime iOS 26.2 con Xcode 27) no termina. Probar: otro simulador/runtime, `simctl erase`, reiniciar CoreSimulator, o Cmd+U en Xcode.
- [x] 3. Bundle id propio para Debug (`com.trackhobbies.app.dev`) en `project.yml`. Falta: primera build de dispositivo para que Xcode registre el App ID con iCloud; en dispositivos que tenían Debug, borrar la app vieja.

## Para retomar
- [ ] 4. Eventos `sync_ok` en PostHog (latencia de sync, lado receptor).
- [ ] 5. Páginas para libros añadidos a mano (ruta nueva del Worker, elegir edición).
- [ ] 6. Enriquecimiento Goodreads por título + autor (Google devuelve 0 con `isbn:`).
- [ ] 7. Backup JSON completo (alternativa barata a Notion).
- [ ] 8. Higiene git: versionar `Package.resolved`, ignorar reordenado de `Localizable.xcstrings`.
- [ ] 9. Importar CSV propio: aviso de cuántos se añadieron/omitidos.
- [ ] 10. Revisar insights de PostHog con datos reales.
- [ ] Notion export (planeada).
- Producto (opcional): widget «ahora leyendo/viendo», recordatorios de progreso, estadísticas por año.

## Decisión `PendingItemEntity`
Código muerto: nadie lo crea ni lo lee. Pero `CD_PendingItemEntity` ya está en el esquema **Production** de CloudKit (no se pueden borrar tipos) y quitarlo exige `SchemaV3` + `MigrationStage` sobre datos reales de iPhone/iPad, sin ningún beneficio funcional.
Se mantiene tal cual. Si algún día se usa (p. ej. recordatorios), ya está desplegado. Retirarlo solo si molesta, junto a otro cambio de esquema.
