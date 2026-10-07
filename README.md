# GST RecoPro — Upload-Ready V14 Baseline

This package is a deployment-ready static build of the existing V13 module-separated development version.

No UI redesign or business-rule rewrite was introduced in this packaging step. The focus is safe deployment structure and validation.

## Structure
- `index.html` — login/workspace
- `pages/` — separate module entry pages
- `js/modules/` — separate module logic
- `css/` — shared styling
- `sample-data/` — sample source fixtures
- `netlify.toml` — Netlify static publish configuration
- `tools/validate.mjs` — local structural validation

## Important
- Data remains browser-local via `localStorage` in this baseline.
- GST API integration is not enabled.
- Excel import uses the SheetJS CDN already referenced by the pages.
- No artificial record-count limit is implemented.
- This package is a stable upload/test baseline, not the final cloud-security production release.
# GST RecoPro V15 — Complete Report Centre

V15 builds on V14 and keeps the module-wise architecture. It adds a practical report centre with detailed reconciliation, party, invoice, monthly, GSTIN, matched, exception, missing, ITC, IMS, 3B comparison and duplicate reports.

## Upload
Static frontend is Netlify-ready using the existing `netlify.toml`.

## Important
Reports are software reconciliation working reports. Statutory filing figures should always be verified against GST portal data before filing.
