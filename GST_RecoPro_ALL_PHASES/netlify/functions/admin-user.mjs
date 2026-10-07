import { createClient } from '@supabase/supabase-js';
function json(body,status=200){return new Response(JSON.stringify(body),{status,headers:{'content-type':'application/json; charset=utf-8','cache-control':'no-store'}})}
export default async function handler(req){
  if(req.method==='OPTIONS') return new Response('',{status:204});
  if(req.method!=='POST') return json({error:'Method not allowed'},405);
  const url=process.env.SUPABASE_URL, serviceKey=process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(!url||!serviceKey) return json({error:'Supabase server environment is not configured.'},500);
  const token=(req.headers.get('authorization')||'').replace(/^Bearer\s+/i,'').trim();
  if(!token) return json({error:'Authentication token required.'},401);
  const admin=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data:callerData,error:callerError}=await admin.auth.getUser(token);
  if(callerError||!callerData?.user) return json({error:'Invalid or expired session.'},401);
  let body;try{body=await req.json()}catch{return json({error:'Invalid JSON body.'},400)}
  const email=String(body.email||'').trim().toLowerCase(),password=String(body.password||''),role=String(body.role||'user').trim().toLowerCase(),companyId=String(body.companyId||'').trim();
  if(!email||!email.includes('@')) return json({error:'Valid user email is required.'},400);
  if(password.length<8) return json({error:'Password must be at least 8 characters.'},400);
  if(!companyId) return json({error:'Company is required.'},400);
  if(!['admin','user'].includes(role)) return json({error:'Role must be ADMIN or USER.'},400);
  const {data:member,error:memberError}=await admin.from('company_members').select('role').eq('company_id',companyId).eq('user_id',callerData.user.id).maybeSingle();
  if(memberError) return json({error:memberError.message},500);
  if(member?.role!=='admin') return json({error:'Company Admin permission is required.'},403);
  let existing=null;
  for(let page=1;page<=10&&!existing;page++){const {data,error}=await admin.auth.admin.listUsers({page,perPage:1000});if(error)return json({error:error.message},500);existing=(data?.users||[]).find(u=>String(u.email||'').toLowerCase()===email);if((data?.users||[]).length<1000)break}
  let userId,action;
  if(existing){userId=existing.id;const {error}=await admin.auth.admin.updateUserById(userId,{password,email_confirm:true});if(error)return json({error:error.message},500);action='reset'}
  else {const {data,error}=await admin.auth.admin.createUser({email,password,email_confirm:true,user_metadata:{app:'GST RecoPro'}});if(error)return json({error:error.message},500);userId=data.user.id;action='create'}
  const {error:upsertError}=await admin.from('company_members').upsert({company_id:companyId,user_id:userId,role,updated_at:new Date().toISOString()});
  if(upsertError)return json({error:upsertError.message},500);
  return json({ok:true,action,userId});
}
