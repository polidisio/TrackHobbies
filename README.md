TrackHobbies - Diario de seguimiento de Series, Libros y Juegos (iPhone + iPad)

Resumen
- Aplicación iOS para registrar y hacer seguimiento de libros, series y juegos.
- Puntuación personal 0–5 con decimales (pasos de 0.25).
- Progreso y tiempo invertido; lista de pendientes por recurso.
- Sincronización entre dispositivos con CloudKit (MVP).
- Búsqueda con APIs públicas para auto-completar datos básicos al añadir recursos:
  - Libros: Open Library
  - Series: TVMaze
  - Juegos: RAWG (clave gratuita opcional; si no hay clave, datos limitados)
- Exportación de datos: CSV para Excel/Sheets; Notion como opción avanzada (opt-in).
- Localización: UI en español por defecto; preparado para inglés.

Estructura de archivos propuesta (inicio)
- AppMain.swift: punto de entrada de la app SwiftUI.
- Models.swift: definiciones de modelos y tipos de dominio.
- Services/
  - OpenLibraryService.swift
  - TVMazeService.swift
  - RAWGService.swift
- Views/
  - ContentView.swift (contenedor principal con pestañas)
  - ResourceRow.swift
- Utils/
  - CSVExporter.swift
  - NotionExporter.swift (opción avanzada)
- Sync/
  - CloudKitSync.swift (placeholder para MVP)

Siguientes pasos propuestos
- Construir el esqueleto de la app y las vistas principales.
- Integrar los servicios de API y el flujo de autocompletar al añadir recursos.
- Implementar la capa de exportación CSV y la integración inicial con Notion como función avanzada.
- Configurar CloudKit y empezar pruebas de sincronización entre iPhone y iPad.

Este archivo no sustituye la planificación completa; es un resumen para empezar a trabajar.
