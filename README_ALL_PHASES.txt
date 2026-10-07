GST RecoPro — Unified All Phases Build

This package consolidates the currently implemented GST RecoPro work so testing can be done in one folder.

INCLUDED / PRESERVED
- Premium GST RecoPro login and Aizen Investment Consultant Private Limited branding
- Cloud Supabase login
- Workspace-first company selection
- Company creation from Workspace only
- Company cards; double-click opens company
- 2B Reco and IMS Matching modules
- 2B / Books / RCM import and period handling
- Duplicate detection
- 2B <-> Books reconciliation engine and statuses
- Notes / manual match controls already present in the source
- IMS B2B/B2BA/DN/CN import handling
- IMS Books import using document date
- IMS matching statuses and Accept / Reject / Pending
- IMS period freeze/reopen controls
- IMS supplier summary, amendments, previous-2B recovery and detailed export
- Company-wise cloud snapshot/RLS architecture
- Backup identity protection: cloud restore is blocked for another company/GSTIN
- Cloud-only company switching from Workspace; redundant module company selectors are hidden
- Netlify functions for Supabase config and Admin User create/reset

COMPUGST-INSPIRED DIRECTION
The supplied CompuGST material was used as a workflow reference, especially the separation of GST modules, 2B/3B comparison, books comparison, import/export, and report-oriented screens. No proprietary CompuGST executable/code is bundled or copied.

LOCAL TEST
1. Double-click run-local.bat
2. Open http://127.0.0.1:5501
3. Use the cloud login configured for your Supabase project.

IMPORTANT
- This is a unified testing build, not a claim that every CompuGST module has already been implemented.
- GST API/automatic portal fetch is intentionally NOT included yet.
- Keep Supabase service-role credentials only in Netlify server environment variables.
