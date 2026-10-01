# CLAUDE.md - TrackHobbies

## Project Overview

**Name:** TrackHobbies  
**Type:** iOS App (SwiftUI)  
**Description:** Hobby tracking app for iPhone + iPad to record and follow books, series, and games. Features scoring (0-5 with 0.25 steps), progress/time tracking, API auto-complete, Goodreads import, CSV export. SwiftData storage synced with CloudKit (private DB, needs a paid team); Notion export is planned, not implemented.  
**Owner:** @polidisio  

## Tech Stack

- **Language:** Swift 5.9+
- **Framework:** SwiftUI
- **Min iOS:** 17.0
- **Architecture:** MVVM
- **Persistence:** SwiftData + CloudKit private DB (`iCloud.com.trackhobbies.app`); models follow CloudKit rules (no `.unique`, defaults, inverse relations)
- **APIs:** Google Books (books), TVMaze (series), IGDB (games, via Cloudflare Worker in `worker/`)
- **Build System:** XcodeGen (project.yml)

## Quick Start

```bash
# Generate Xcode project
xcodegen generate

# Open in Xcode
open TrackHobbies.xcodeproj

# Build (Cmd+R)
```

## File Structure

```
TrackHobbies/
├── AppMain.swift           # App entry point
├── BookStore.swift         # Book-specific logic
├── ContentView.swift       # Main container with tabs
├── Models/                # SwiftData entities + enums
├── Services/              # API services
│   ├── GoogleBooksService.swift
│   ├── GoodreadsImporter.swift
│   ├── TVMazeService.swift
│   ├── GameSearchService.swift
│   └── HTTP.swift
├── Utils/
│   ├── CSVExporter.swift
├── Theme/
├── Views/
├── ViewModels/
├── Assets.xcodeproj
├── project.yml
├── AGENTS.md
├── README.md
└── CLAUDE.md
```

## Features

- ✅ **Resources:** Books, Series, Games
- ✅ **Scoring:** 0-5 with 0.25 steps
- ✅ **Progress tracking:** Time invested
- ✅ **CloudKit sync:** enabled (`DataStore`, schema V2). Set `DEVELOPMENT_TEAM` in `Config/Secrets.xcconfig`; test on two real devices
- ✅ **API auto-complete:**
  - Books: Google Books
  - Series: TVMaze
  - Games: IGDB through the Worker (needs `Config/Secrets.xcconfig`)
- ✅ **Export:** CSV (Excel/Sheets). Notion: not implemented
- ✅ **Localization:** Spanish (source) + English via `Localizable.xcstrings`. Keys are the Spanish strings; use `String(localized:)` for any text that is not a SwiftUI literal

## Architecture

### Pattern: MVVM
- **Models:** Book, Series, Game with common interface
- **ViewModels:** Manage state per resource type
- **Services:** External API clients

### CloudKit Sync
- Container: `iCloud.com.trackhobbies.app`
- Services: CloudKit

## Important Rules

### ✅ Always Do
- Test CloudKit sync on real devices
- Handle game search gracefully (Worker not configured or offline = visible error, never crash)
- Follow MVVM separation

### ❌ Never Do
- Commit API keys to source
- Overwrite local data without confirmation

## Resources

- Token optimization tips: `shared/claude-optimization-tips.md` (Obsidian Vault)

---

**Owner:** Jose Maudisio (@polidisio)  
**Last updated:** 2026-04-24

---

---

## Workflow

### Para tareas simples
Sé directo: "Añade validación al form" — no necesitas explicar contexto.

### Para tareas complejas (>3 pasos)
1. Agent propone plan primero
2. Usuario confirma
3. Agent ejecuta
4. Agent verifica con tests

### Para cada tarea
1. **Plan** → Si son >3 pasos, escribir en `tasks/todo.md`
2. **Verify** → Confirmar antes de cambios grandes
3. **Execute** → Cambio más pequeño posible
4. **Test** → Ejecutar tests, verificar regression
5. **Document** → Actualizar si es necesario

---

## Code Quality

### SIEMPRE
- Código legible y mantenible
- Seguir convenciones del proyecto
- DRY — no duplicar lógica
- Validar input antes de procesar

### NUNCA
- Hardcodear credenciales o tokens
- "Hacky fixes" sin justificación
- Duplicar código sin razón
- Commits sin mensaje descriptivo

---

## Security

- **NUNCA hardcodear** credenciales — usar environment variables
- **NUNCA exponer** tokens en logs o errores
- **Validar input** antes de procesar
- Si hay secrets, usar `.env` y nunca commitearlo

---

## Self-Improvement

### Si cometes un error
1. Documentar en `lessons.md` — qué salió mal, por qué, cómo evitarlo
2. Actualizar este archivo si la convención no estaba clara
3. No repetir

### Si descubres algo útil
- Documentar en notas del proyecto
- Compartir con Jose si es relevante

---

## Token Optimization

### Hacer
- Agrupar múltiples requests en uno
- Editar en vez de reply (menos historial)
- Nuevo tema = nueva conversación
- Planificar en chat, construir en workspace

### Evitar
- Subir carpetas enteras — solo archivos necesarios
- Múltiples prompts cortos seguidos
- Usar Opus para tareas simples
- Mantener contexto irrelevante

**Budget:** ~88% de tokens en conversaciones largas = solo historial. Mantenerlo limpio.

---

## Resources

**Obsidian Vault:** `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Saraiba/`

| Recurso | Ubicación en Vault |
|---------|---------------------|
| Best practices | `shared/coding-best-practices.md` |
| Optimization tips | `shared/claude-optimization-tips.md` |
| Skills docs | `shared/openclw-skills.md` |
| Guía coding agents | `shared/guia-coding-agents.md` |

---

## Contact

**Jose Maudisio** — @polidisio
**Issues:** Abrir en GitHub o preguntar en Telegram
