#!/usr/bin/env python3
"""Build the one-file FTP deliverable. Uses only the Python standard library."""
from pathlib import Path
import base64
import html
import json
import mimetypes
import re

HERE = Path(__file__).resolve().parent
STORE = HERE.parent
RELEASE = json.loads((HERE / "release.json").read_text())
DMG = RELEASE["dmg_url"]


def data_uri(path: Path) -> str:
    mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    return f"data:{mime};base64,{base64.b64encode(path.read_bytes()).decode()}"


def main() -> None:
    files = {
        "ICON": HERE / "assets/icon.webp",
        "FONT": HERE / "assets/manrope-bold.ttf",
        "PANEL": HERE / "assets/panel.webp",
        "SECOND": HERE / "assets/second-bar.webp",
        "AUDIT": HERE / "assets/audit.webp",
        "CHROME": STORE / "assets/app-icons/chrome.png",
        "VSCODE": STORE / "assets/app-icons/vscode.png",
        "WHATSAPP": STORE / "assets/app-icons/whatsapp.png",
        "POSTER": HERE / "assets/film-poster.webp",
        "VIDEO": STORE / "videos/pkmonitor-landing.mp4",
        "LANDSCAPE": HERE / "assets/observatory-coast.webp",
        "GARDEN": HERE / "assets/woodland-lagoon.webp",
    }
    template = (HERE / "index.template.html").read_text()
    template = template.replace("@@STYLES@@", (HERE / "immersive.css").read_text())
    template = template.replace("@@IMMERSIVE_JS@@", (HERE / "immersive.js").read_text())
    for token, path in files.items():
        template = template.replace(f"@@{token}@@", data_uri(path))
    template = template.replace("@@DMG_URL@@", html.escape(DMG, quote=True))
    installer = (HERE / "install-command.sh").read_text().replace("@@DMG_URL@@", DMG).strip()
    template = template.replace("@@CURL_COMMAND@@", html.escape(installer))
    unresolved = re.findall(r"@@[A-Z_]+@@", template)
    if unresolved:
        raise RuntimeError(f"Unresolved assets: {unresolved}")
    license_text = (HERE / "assets/OFL-Manrope.txt").read_text().replace("--", "—")
    template = template.replace("</head>", f"<!-- Embedded Manrope font license:\n{license_text}\n-->\n</head>")
    output = STORE / "index.html"
    output.write_text(template)
    print(f"Built {output.relative_to(STORE.parent)} — {output.stat().st_size / 1_000_000:.2f} MB")


if __name__ == "__main__":
    main()
