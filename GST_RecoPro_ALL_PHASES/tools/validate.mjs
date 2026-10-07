import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const required = [
  'index.html', 'css/app.css', 'js/core.js',
  'pages/company.html', 'pages/party-master.html', 'pages/gst-home.html',
  'pages/gstr2b.html', 'pages/ims.html', 'pages/books.html',
  'pages/reconciliation.html', 'pages/reports.html', 'pages/utilities.html',
  'js/modules/company-master.js', 'js/modules/party-master.js',
  'js/modules/2b.js', 'js/modules/ims.js', 'js/modules/books.js',
  'js/modules/matching-engine.js', 'js/modules/import-engine.js',
  'js/modules/reconciliation.js', 'js/modules/reports.js',
  'js/modules/utilities.js', 'js/modules/shared-ui.js'
];

const missing = required.filter(f => !fs.existsSync(path.join(root, f)));
if (missing.length) {
  console.error('Missing files:', missing.join(', '));
  process.exit(1);
}

const htmlFiles = [
  'index.html', ...fs.readdirSync(path.join(root, 'pages')).filter(f => f.endsWith('.html')).map(f => `pages/${f}`)
];
const broken = [];
for (const file of htmlFiles) {
  const text = fs.readFileSync(path.join(root, file), 'utf8');
  const refs = [...text.matchAll(/(?:href|src)=["']([^"']+)["']/g)].map(m => m[1]);
  for (const ref of refs) {
    if (/^(https?:|mailto:|#|javascript:)/i.test(ref)) continue;
    const clean = ref.split('?')[0].split('#')[0];
    const target = path.resolve(path.dirname(path.join(root, file)), clean);
    if (!fs.existsSync(target)) broken.push(`${file} -> ${ref}`);
  }
}
if (broken.length) {
  console.error('Broken local references:\n' + broken.join('\n'));
  process.exit(1);
}
console.log(`GST RecoPro validation passed: ${htmlFiles.length} HTML pages, all required local references resolved.`);
