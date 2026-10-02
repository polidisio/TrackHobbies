#!/usr/bin/env python3
"""Incrusta architecture.json en architecture.html (abrir el HTML con file:// no permite fetch).

Uso: python3 Docs/architecture/build.py
Edita architecture.json, ejecuta este script y recarga el HTML.
"""
import json
import re
from pathlib import Path

here = Path(__file__).parent
data = json.loads((here / "architecture.json").read_text(encoding="utf-8"))
# "</" dentro de un <script> cerraría la etiqueta antes de tiempo
payload = json.dumps(data, ensure_ascii=False, indent=2).replace("</", "<\\/")
block = f'<!--DATA-->\n<script id="arch-data" type="application/json">{payload}</script>\n<!--/DATA-->'

html_path = here / "architecture.html"
html = html_path.read_text(encoding="utf-8")
new, n = re.subn(r"<!--DATA-->.*?<!--/DATA-->", lambda _: block, html, count=1, flags=re.S)
assert n == 1, "No encuentro los marcadores <!--DATA--> en architecture.html"
html_path.write_text(new, encoding="utf-8")
print(f"OK: {len(payload):,} caracteres de datos incrustados en {html_path.name}")
