#!/usr/bin/env python3
"""Régénère appcast-dev.xml avec un item unique : le dernier build dev signé.

Usage: sparkle_dev_release.py <zip> <bundle-version> <short-version>
La clé privée (base64, raw ed25519) est lue dans SPARKLE_PRIVATE_KEY.
Le canal dev n'accumule pas d'historique : l'appcast ne contient toujours
que le build le plus récent (sparkle:version = timestamp epoch, strictement
croissant et toujours supérieur aux versions stable CalVer).
"""
import base64
import datetime
import os
import pathlib
import sys

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey


def main() -> None:
    zip_path, bundle_version, short_version = sys.argv[1], sys.argv[2], sys.argv[3]
    data = pathlib.Path(zip_path).read_bytes()
    key = Ed25519PrivateKey.from_private_bytes(base64.b64decode(os.environ["SPARKLE_PRIVATE_KEY"].strip()))
    signature = base64.b64encode(key.sign(data)).decode()
    pub_date = datetime.datetime.now(datetime.timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")

    xml = f"""<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>PKMonitor (dev)</title>
    <link>https://raw.githubusercontent.com/mondary/PKmonitor/main/appcast-dev.xml</link>
    <description>Builds automatiques du canal dev — item unique, toujours le plus récent.</description>
    <language>en</language>
    <item>
      <title>PKMonitor {short_version}</title>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{bundle_version}</sparkle:version>
      <sparkle:shortVersionString>{short_version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <description>Build dev automatique depuis main (canal dev : installation silencieuse).</description>
      <enclosure url="https://github.com/mondary/PKmonitor/releases/download/dev/PKMonitor-dev.zip" type="application/octet-stream" sparkle:edSignature="{signature}" length="{len(data)}" />
    </item>
  </channel>
</rss>
"""
    pathlib.Path("appcast-dev.xml").write_text(xml, encoding="utf-8")
    print(f"appcast-dev.xml written for {bundle_version} ({short_version}, {len(data)} bytes, edSignature OK)")


if __name__ == "__main__":
    main()
