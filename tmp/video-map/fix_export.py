from pathlib import Path
p=Path('artifacts/os13-video-map/studio.html');s=p.read_text(encoding='utf-8')
s=s.replace('252–1332','256–1324').replace('cx:252/1920*reference.vw','cx:256/1920*reference.vw').replace('cw:1080/1920*reference.vw','cw:1068/1920*reference.vw')
s=s.replace('id="autoreconcile" type="checkbox" checked','id="autoreconcile" type="checkbox"')
s=s.replace('<label style="flex-direction:row;align-items:center;gap:8px"><input id="autoreconcile"','<label style="flex-direction:row;align-items:center;gap:8px"><input id="autojoin" type="checkbox" style="width:auto"> Automatically merge regions during capture (review recommended before enabling)</label><label style="flex-direction:row;align-items:center;gap:8px"><input id="autoreconcile"')
s=s.replace('if(activeZ>=0&&levels.length>1&&levels[activeZ].prev===pr)',"if($('autojoin').checked&&activeZ>=0&&levels.length>1&&levels[activeZ].prev===pr)")
s=s.replace(' return best;\n}\n// Compute luminance', ''' if(!coarseOnly&&!motionSupport(P,N,best[1],best[2]).ok)return[1e9,0,0];
 return best;
}
// Require matching detail in separated parts of the viewport. A character,
// popup, or a small surviving floor patch cannot establish camera motion.
function motionSupport(P,N,dx,dy){
 const A=P.g2,B=N.g2,cells=Array.from({length:16},()=>({n:0,close:0,edge:0}));
 dx=Math.round(dx/2);dy=Math.round(dy/2);
 for(let y=Math.max(1,dy+1);y<Math.min(A.h-1,B.h+dy-1);y+=3)for(let x=Math.max(1,dx+1);x<Math.min(A.w-1,B.w+dx-1);x+=3){
  const i=y*A.w+x,j=(y-dy)*B.w+x-dx;if(!A.valid[i]||!B.valid[j])continue;
  const c=cells[Math.min(3,Math.floor(y*4/A.h))*4+Math.min(3,Math.floor(x*4/A.w))];c.n++;
  const edge=Math.abs(A.g[i-1]-A.g[i+1])+Math.abs(A.g[i-A.w]-A.g[i+A.w]);
  if(edge>=12){c.edge++;if(Math.abs(A.g[i]-B.g[j])<=28)c.close++}
 }
 const supported=cells.map((c,i)=>({c,i})).filter(({c})=>c.n>=12&&c.edge>=8&&c.close/c.edge>=.65);
 const rows=new Set(supported.map(q=>q.i>>2)),cols=new Set(supported.map(q=>q.i%4));
 return{ok:supported.length>=3&&rows.size>=2&&cols.size>=2,cells:supported.length};
}
// Compute luminance''')
s=s.replace('q.count>=80&&q.coverage>=.35&&q.close<.32&&q.mean>48','q.count>=80&&q.coverage>=.25&&q.close<.55&&q.mean>30')
s=s.replace('Math.min(255,b.cnt[j]+a.cnt[i])','Math.min(8,b.cnt[j]+a.cnt[i])')
s=s.replace("version:5,", "version:6,")
s=s.replace("'confirm','maxz'].map", "'confirm','maxz'].map")
s=s.replace("sources:importedSources.length?importedSources:queue.map((e,i)=>", "automaticJoining:$('autojoin').checked,automaticReconciliation:$('autoreconcile').checked,sources:importedSources.length?importedSources:queue.map((e,i)=>")
p.write_text(s,encoding='utf-8')
