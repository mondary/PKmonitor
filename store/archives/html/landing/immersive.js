(() => {
  'use strict';
  const $=s=>document.querySelector(s);
  const demo=$('.native-demo');
  const header=$('#mac-menubar');
  const activity=$('#menu-activity');
  const opener=$('#native-open');
  const audit=$('#native-audit-panel');
  let intentionalOpen=false;
  const setOpen=value=>{
    demo.classList.toggle('menu-closed',!value);
    activity.setAttribute('aria-expanded',String(value));
    opener.setAttribute('aria-expanded',String(value));
    $('#process-panel').inert=!value;
  };
  const toggle=()=>{intentionalOpen=true;setOpen(demo.classList.contains('menu-closed'));};
  activity.addEventListener('click',toggle);
  opener.addEventListener('click',toggle);
  $('#native-close').addEventListener('click',()=>{setOpen(false);activity.focus();});
  document.querySelectorAll('.gauge-button').forEach(b=>b.addEventListener('click',()=>{intentionalOpen=true;setOpen(true);}));
  function secondMode(value){header.classList.toggle('second-mode',value);$('#native-second').setAttribute('aria-pressed',String(value));$('#native-second').lastChild.textContent=value?' Barre macOS':' Seconde barre';}
  $('#native-second').addEventListener('click',()=>{intentionalOpen=true;secondMode(!header.classList.contains('second-mode'));});
  $('#native-audit').addEventListener('click',()=>{audit.hidden=!audit.hidden;if(!audit.hidden){$('#native-audit-close').focus();}});
  $('#native-audit-close').addEventListener('click',()=>{audit.hidden=true;$('#native-audit').focus();});
  $('#native-audit-more').addEventListener('click',()=>{audit.hidden=true;setOpen(false);});
  document.addEventListener('keydown',event=>{if(event.key!=='Escape')return;if(!audit.hidden){audit.hidden=true;$('#native-audit').focus();}else if($('#demo-confirm').hidden&&!$('#image-dialog').open){setOpen(false);activity.focus();}});
  document.addEventListener('click',event=>{if(!header.contains(event.target)&&!audit.contains(event.target)&&scrollY>220){setOpen(false);audit.hidden=true;}});
  let didAutoClose=false;
  addEventListener('scroll',()=>{if(scrollY>260&&!didAutoClose&&!intentionalOpen&&$('#demo-confirm').hidden){setOpen(false);didAutoClose=true;}},{passive:true});
  $('.interaction-hint').textContent='↖ Essayez les jauges dans la barre, tout en haut.';
  document.querySelectorAll('.feature-dock a,.mac-left nav a').forEach(a=>a.addEventListener('click',()=>{setOpen(false);audit.hidden=true;}));
  setOpen(true);
})();
