# GST RecoPro — Complete deployable package

This is the complete Netlify deployable folder for the current GST RecoPro cloud app.

Included:
- index.html
- netlify.toml
- package.json
- netlify/functions/config.mjs
- netlify/functions/admin-user.mjs

The existing Supabase database/schema does not need to be changed for the 10 requested UI/IMS changes.

Keep the existing Netlify environment variables:
- SUPABASE_URL
- SUPABASE_PUBLISHABLE_KEY
- SUPABASE_SERVICE_ROLE_KEY (server-side only)
