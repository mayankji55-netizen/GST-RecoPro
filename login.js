const form=document.getElementById('loginForm');
const password=document.getElementById('password');
const show=document.getElementById('showBtn');
const message=document.getElementById('message');

show.addEventListener('click',()=>{
  const visible=password.type==='text';
  password.type=visible?'password':'text';
  show.textContent=visible?'Show':'Hide';
});

form.addEventListener('submit',e=>{
  e.preventDefault();
  message.textContent='';
  const id=document.getElementById('userId').value.trim();
  const pass=password.value;
  if(!id||!pass){message.textContent='Please enter User ID and Password.';return;}
  message.textContent='Authentication will use the existing login system.';
});
