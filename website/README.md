# Tauber Defence Website

Product, support, privacy, and app-capability pages for App Store compliance.

```bash
npm ci
npm run dev
npm run lint
npm run build
```

The static export is written to `dist/client`. A post-build step mirrors each
route to a directory index so `/support/`, `/privacy/`, and `/capabilities/`
work on GitHub Pages.
