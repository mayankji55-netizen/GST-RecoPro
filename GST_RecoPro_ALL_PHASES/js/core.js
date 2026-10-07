const DB_KEY='gstrecopro_v13';
const DEFAULT_DB={version:13,companies:[],activeCompany:null,fy:'2026-27',selectedPeriod:'2026-09',dataByCompany:{},locks:{}};
let db=loadDB();
function loadDB(){try{return Object.assign({},DEFAULT_DB,JSON.parse(localStorage.getItem(DB_KEY)||'null')||{})}catch{return {...DEFAULT_DB}}}
function save(){localStorage.setItem(DB_KEY,JSON.stringify(db))}
function esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
function num(v){const n=Number(String(v??'').replace(/,/g,''));return Number.isFinite(n)?n:0}
function cleanGSTIN(v){return String(v??'').trim().toUpperCase()}
function money(v){return num(v).toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2})}
function fmtDate(v){return String(v??'').trim()}
function current(){return db.companies.find(c=>c.id===db.activeCompany)||null}
function companyData(id=db.activeCompany){if(!id)return {data:{'2B':[],IMS:[],Books:[]},parties:[],notes:{},imsDecisions:{}};if(!db.dataByCompany[id])db.dataByCompany[id]={data:{'2B':[],IMS:[],Books:[]},parties:[],notes:{},imsDecisions:{}};const x=db.dataByCompany[id];x.data??={'2B':[],IMS:[],Books:[]};x.data['2B']??=[];x.data.IMS??=[];x.data.Books??=[];x.parties??=[];x.notes??={};x.imsDecisions??={};return x}
function activeData(){return companyData()}
function isFrozen(){return !!db.locks[`${db.activeCompany}|${db.selectedPeriod}`]}
function guardWrite(){if(isFrozen()){alert('Current period is frozen. Reopen the period before changing data.');return false}return true}
function setStatus(msg){const e=document.getElementById('statusText');if(e)e.textContent=msg}
function toast(msg){setStatus(msg);const e=document.getElementById('toast');if(e){e.textContent=msg;e.classList.add('show');clearTimeout(window.__toast);window.__toast=setTimeout(()=>e.classList.remove('show'),2400)}}
function login(){const u=document.getElementById('loginUser')?.value.trim(),p=document.getElementById('loginPass')?.value;if(!u||!p)return alert('User ID aur Password enter karein.');sessionStorage.setItem('gstrecopro_logged_in','1');document.getElementById('login')?.classList.add('hidden');document.getElementById('app')?.classList.remove('hidden');syncContext();renderIndexWorkspace();if(document.getElementById('loginPass'))document.getElementById('loginPass').value='';if(document.getElementById('loginUser'))document.getElementById('loginUser').value=''}
function logout(){sessionStorage.removeItem('gstrecopro_logged_in');location.href=location.pathname.toLowerCase().endsWith('/index.html')||!location.pathname.includes('/pages/')?'index.html':'../index.html'}
function bootIndex(){if(sessionStorage.getItem('gstrecopro_logged_in')==='1'){document.getElementById('login')?.classList.add('hidden');document.getElementById('app')?.classList.remove('hidden');syncContext();renderIndexWorkspace()}}
function requireSession(){if(sessionStorage.getItem('gstrecopro_logged_in')!=='1'){location.href='../index.html';return false}return true}
function syncContext(){const c=current();for(const [id,v] of [['ctxCompany',c?.name||'No company selected'],['ctxGSTIN',c?.gstin||'—'],['ctxFY',c?.fy||db.fy],['ctxMini',c?.name||'No Company']]){const e=document.getElementById(id);if(e)e.textContent=v}}
function renderIndexWorkspace(){const e=document.getElementById('main');if(!e)return;e.innerHTML=`<div class="screen-head"><div><h1>GST RecoPro Workspace</h1><p>Company-centric GST working environment</p></div><div class="toolbar"><a class="btn primary" href="pages/company.html">Open Company Master</a><a class="btn" href="pages/gst-home.html">GST Home</a></div></div><div class="grid"><a class="tile" href="pages/company.html"><b>Company Master</b><p>${db.companies.length} companies</p></a><a class="tile" href="pages/party-master.html"><b>Party Master</b><p>Create and maintain company-wise parties</p></a><a class="tile" href="pages/gstr2b.html"><b>GSTR-2B</b><p>${activeData().data['2B'].length} imported records</p></a><a class="tile" href="pages/ims.html"><b>IMS</b><p>${activeData().data.IMS.length} imported records</p></a><a class="tile" href="pages/books.html"><b>Books</b><p>${activeData().data.Books.length} imported records</p></a><a class="tile" href="pages/reconciliation.html"><b>Reconciliation</b><p>2B ⇄ Books matching</p></a></div>`}
function pageBoot(){if(!requireSession())return;syncContext();const n=location.pathname.toLowerCase().split('/').pop();const map={'company.html':'companyMaster','party-master.html':'partyMaster','gst-home.html':'gstHome','gstr2b.html':'twoBModule','ims.html':'imsModule','books.html':'booksModule','reconciliation.html':'recoModule','reports.html':'reportsModule','utilities.html':'utilitiesModule'};const mod=map[n];if(mod&&window[mod]?.init)window[mod].init()}
function navBack(){history.length>1?history.back():location.href='../index.html'}
function pageChrome(title,sub,body){return `<div class="screen-head"><div><h1>${esc(title)}</h1><p>${esc(sub||'')}</p></div><div class="toolbar"><a class="btn" href="../index.html">Home</a><a class="btn" href="company.html">Company</a><a class="btn" href="party-master.html">Party Master</a></div></div>${body}`}
function moduleHeader(title,sub,buttons=''){const c=current();return `<div class="screen-head"><div><h1>${esc(title)}</h1><p>${esc(sub||'')}${c?` · ${esc(c.name)} · GSTIN ${esc(c.gstin||'—')} · FY ${esc(c.fy||db.fy)}`:''}</p></div><div class="toolbar">${buttons}</div></div>`}
function clearCurrentOnChange(){syncContext();save()}
function openPage(path){location.href=path}
function createId(){return crypto.randomUUID?crypto.randomUUID():`${Date.now()}-${Math.random()}`}
window.appCore={init:pageBoot};
