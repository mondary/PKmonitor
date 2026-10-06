#!/usr/bin/env python3
"""Signe un DMG avec la cle EdDSA Sparkle et ajoute son entree a appcast.xml.

Usage: sparkle_release.py <dmg> <version> <notes-file>
La cle privee (base64, raw ed25519) est lue dans SPARKLE_PRIVATE_KEY.
"""
import base64
import datetime
import html
import os
import pathlib
import re
import sys

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey


def main() -> None:
    dmg_path, version, notes_path = sys.argv[1], sys.argv[2], sys.argv[3]
    dmg = pathlib.Path(dmg_path).read_bytes()
    key_bytes = base64.b64decode(os.environ["SPARKLE_PRIVATE_KEY"].strip())
    key = Ed25519PrivateKey.from_private_bytes(key_bytes)
    signature = base64.b64encode(key.sign(dmg)).decode()

    notes = pathlib.Path(notes_path).read_text().strip()
    pub_date = datetime.datetime.now(datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")
    dmg_name = pathlib.Path(dmg_path).name
    url = f"https://github.com/mondary/PKmonitor/releases/download/v{version}/{dmg_name}"
    item = f"""      <item>
        <title>PKMonitor {version}</title>
        <pubDate>{pub_date}</pubDate>
        <sparkle:version>{version}</sparkle:version>
        <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
        <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        <description>{html.escape(notes)}</description>
        <enclosure url="{url}" type="application/x-bzip2" sparkle:edSignature="{signature}" length="{len(dmg)}" />
      </item>"""

    path = pathlib.Path("appcast.xml")
    text = path.read_text()
    text = re.sub(r"(?m)^\s*</channel>", item + "\n  </channel>", text, count=1)
    path.write_text(text)
    print(f"appcast.xml updated for {version} ({len(dmg)} bytes, edSignature OK)")


if __name__ == "__main__":
    main()
