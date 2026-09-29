# GST RecoPro — Cloud / Multi-Company deployment

## 1. Create Supabase project
Create a Supabase project.

## 2. Run the database schema
In Supabase → SQL Editor, run **supabase_schema.sql** from this package.

The schema creates:
- companies
- company_members
- company_snapshots
- company_period_locks
- RLS policies and secure RPCs

## 3. Configure Netlify environment variables
In Netlify → Site configuration → Environment variables, add:

- `SUPABASE_URL` = your Supabase project URL
- `SUPABASE_PUBLISHABLE_KEY` = your Supabase publishable key (older projects may call this the anon key)
- `SUPABASE_SERVICE_ROLE_KEY` = your Supabase service-role key (**server only**)

Never put the service-role key into index.html, localStorage, or any browser-visible config.

## 4. Deploy the whole package
Upload/deploy the entire folder, not only the HTML file. The package contains:

- `index.html` — GST RecoPro application
- `netlify.toml` — Netlify routing
- `netlify/functions/` — server-side user management/config
- `package.json` — Netlify Function dependency
- `supabase_schema.sql` — database setup

The supplied `GST_RecoPro_FINAL_CLOUD.html` should be renamed to **index.html** in the Netlify publish folder.

## 5. First login
Open the deployed site.

Use **Create First Admin Account** once to create the first Supabase Auth account. If Supabase email confirmation is enabled, confirm the email and then log in.

After the first Admin logs in, create the first company. The Admin becomes the owner/admin of that company.

## 6. Add more companies
Select **+ Company** from the cloud company bar. Each company has its own snapshot and membership records.

## 7. Add Users
From 2B → Data / Settings → Security & Users → **Create / Reset User**.

The server-side Netlify function creates/resets the Supabase Auth user and assigns that user to the currently selected company.

## 8. Important data model behavior
One Supabase project can hold multiple companies. Each logged-in user only sees companies for which a `company_members` row exists. The app loads the selected company's 2B, Books, RCM, IMS, IMS Books, decisions and notes into the working view.

IMS remains a separate workspace from the existing 2B reconciliation flow.

Frozen 2B/IMS period metadata is stored separately in `company_period_locks` and is admin-controlled.

## 9. Existing local data
The cloud version does not automatically upload an old `GST_Recon_Data.json` file into a company, because blindly importing a local file could put the wrong company's GST data into the cloud. Use the app's backup/restore workflow only after selecting the intended company, or migrate the data deliberately.
