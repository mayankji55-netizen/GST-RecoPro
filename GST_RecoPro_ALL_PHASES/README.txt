GST RecoPro - Separate Login Design

Files:
- login.html
- login.css
- login.js

This login page is intentionally isolated from the dashboard/application CSS.
It does not pre-fill User ID or Password.

To integrate:
1. Keep these three files together.
2. Point the existing login route/page to login.html.
3. Connect the existing authentication logic inside login.js.
4. Do not merge login.css into the dashboard stylesheet; this keeps the login design isolated.
