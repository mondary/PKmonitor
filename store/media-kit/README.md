# Store website bundle

The deployable page is generated from `store/index.html` directly into
`store/website/`. The website bundle is ignored by Git so the editable
source remains the single source of truth.

From the repository root, regenerate it after changing the landing page:

```sh
sh scripts/website.sh
```

The current landing embeds its fonts, icons, illustrations, styles and scripts
directly in `index.html`; therefore `store/website/` contains only that file.
Upload the contents of `store/website/` directly to the FTP destination. The page
makes a runtime request to GitHub's public Releases API to resolve the latest DMG;
it does not require local runtime assets.
