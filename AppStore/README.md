# Capturas de App Store

Tamaños que pide App Store Connect: **iPhone 6,9" = 1320×2868** (iPhone 18 Pro Max) e **iPad 13" = 2064×2752** (iPad Pro 13" M5).
Las imágenes generadas viven en `AppStore/Screenshots/en/` (no van a git, pesan ~33 MB):

- `iphone_6.9/` (8) y `ipad_13/` (5): listas para subir, con titular y fondo de marca.
- `raw/`: capturas limpias sin titular, por si quieres otro diseño.

## Cómo repetirlas

1. **Datos de ejemplo.** `python3 AppStore/tools/fetch.py raw.json` busca portadas reales (Worker + TVMaze) y `python3 AppStore/tools/build.py <carpeta>` genera `demo.json`
   (formato de la copia de seguridad; 9 libros, 6 series, 6 juegos con estados, progreso y puntuaciones). Las rutas esperan `<carpeta>/store/raw.json`.
2. **Simulador limpio:** `xcrun simctl uninstall <udid> com.trackhobbies.app.dev`, barra de estado
   `xcrun simctl status_bar <udid> override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3`, `xcrun simctl ui <udid> appearance light`.
   Para fechas en inglés en el iPad: `xcrun simctl spawn <udid> defaults write NSGlobalDomain AppleLanguages -array en` y reiniciar el simulador.
3. **Lanzar con los datos:** build Debug con los argumentos `-SeedDemo /ruta/demo.json -AppleLanguages (en) -AppleLocale en_US`
   (`Utils/DemoSeed.swift`, solo existe en Debug; también marca el consentimiento de analítica como respondido).
4. **Capturar** a tamaño nativo: `xcrun simctl io <udid> screenshot archivo.png`.
5. **Componer:** `python3 AppStore/tools/compose.py <carpeta_raw> <salida>` (nombres `iphone_en_NN_*.png` / `ipad_en_NN_*.png`; editar los titulares dentro del script).

Notas: las portadas son de terceros (Google Books, TVMaze, IGDB); conviene revisar si quieres usarlas tal cual en la ficha.
Para español: repetir con `-AppleLanguages (es)` y traducir los titulares de `compose.py`.
