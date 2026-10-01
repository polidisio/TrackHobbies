TrackHobbies - Diario de seguimiento de Series, Libros y Juegos (iPhone + iPad)

Resumen
- Aplicación iOS para registrar y hacer seguimiento de libros, series y juegos.
- Puntuación personal 0–5 con decimales (pasos de 0.25).
- Progreso y tiempo invertido; lista de pendientes por recurso.
- Almacenamiento con SwiftData sincronizado vía CloudKit (base privada; requiere `DEVELOPMENT_TEAM` en `Config/Secrets.xcconfig`).
- Búsqueda con APIs públicas para auto-completar datos básicos al añadir recursos:
  - Libros: Google Books
  - Series: TVMaze
  - Juegos: IGDB, a través de un Worker de Cloudflare (`worker/`)
- Exportación de datos: CSV para Excel/Sheets (Notion pendiente).
- Localización: UI en español e inglés (`Localizable.xcstrings`).
- Analytics opt-in con PostHog (`Docs/ANALYTICS.md`): solo uso anónimo, nunca contenido.

Estructura de archivos propuesta (inicio)
- AppMain.swift: punto de entrada de la app SwiftUI.
- Models.swift: definiciones de modelos y tipos de dominio.
- Services/
  - GoogleBooksService.swift
  - TVMazeService.swift
  - GameSearchService.swift
- Views/
  - ContentView.swift (contenedor principal con pestañas)
  - ResourceRow.swift
- Utils/
  - CSVExporter.swift

Siguientes pasos propuestos
- Construir el esqueleto de la app y las vistas principales.
- Integrar los servicios de API y el flujo de autocompletar al añadir recursos.
- Implementar la capa de exportación CSV y la integración inicial con Notion como función avanzada.
- Probar la sincronización CloudKit entre iPhone y iPad reales y desplegar el esquema a producción.

Este archivo no sustituye la planificación completa; es un resumen para empezar a trabajar.
