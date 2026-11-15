'use strict';
const form=document.querySelector('#editor'), status=document.querySelector('#status');
const events=document.querySelector('#events');
let selected=null;
document.querySelector('#timezone').textContent='Times use '+Intl.DateTimeFormat().resolvedOptions().timeZone+'.';
function local(value){
 const date=new Date(value);
 return new Date(date.getTime()-date.getTimezoneOffset()*60000).toISOString().slice(0,16);
}
function select(event){
 selected=event?.id??null;
 form.reset();
 if(!event)return;
 for(const key of ['title','location','species'])form.elements[key].value=event[key];
 for(const key of ['starts','ends'])form.elements[key].value=local(event[key]);
}
async function load(){
 const response=await fetch('/admin/derbies/api');
 const data=await response.json();
 if(!response.ok)throw Error(data.error);
 for(const key of ['location','species']){
  const input=form.elements[key];
  input.length=1;
  for(const option of data[key==='location'?'locations':'species'])input.add(new Option(option.name,option.id));
 }
 events.replaceChildren();
 for(const event of data.events){
  const row=document.createElement('p');
  row.textContent=event.title+' · '+(event.published?'Published':'Draft')+' · '+new Date(event.starts).toLocaleString()+' – '+new Date(event.ends).toLocaleString()+' ';
  if(!event.published){
   const edit=document.createElement('button');edit.textContent='Edit draft';
   edit.onclick=()=>select(event);row.append(edit);
  }
  events.append(row);
 }
 if(!data.events.length)events.textContent='No events yet.';
}
document.querySelector('#new').onclick=()=>select(null);
form.addEventListener('submit',async event=>{
 event.preventDefault();
 const data=Object.fromEntries(new FormData(form));
 for(const key of ['starts','ends'])data[key]=new Date(data[key]).toISOString();
 data.id=selected;data.published=event.submitter.value==='publish';
 try{
  const response=await fetch('/admin/derbies/api',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});
  if(!response.ok)throw Error((await response.json()).error);
  select(null);await load();
  status.textContent=data.published?'Derby published.':'Draft saved.';
 }catch(error){status.textContent=error.message;}
});
load().catch(error=>{status.textContent=error.message;});
