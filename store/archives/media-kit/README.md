# Store website bundle

The deployable page is generated from `store/index.html` into
`store/website/pkmonitor/`. The website bundle is ignored by Git so the editable
source remains the single source of truth.

From the repository root, regenerate it after changing the landing page:

```sh
sh scripts/website.sh
```

The current landing embeds its fonts, icons, illustrations, styles and scripts
directly in `index.html`; therefore the generated `pkmonitor/` directory contains
only that file. Drag the `pkmonitor/` directory to the FTP destination to publish
it under `/pkmonitor/`. The page makes a runtime request to GitHub's public
Releases API to resolve the latest DMG; it does not require local runtime assets.
