from pathlib import Path
p=Path('artifacts/os13-video-map/studio.html')
s=p.read_text(encoding='utf-8')
s=s.replace('<canvas id="pv"></canvas>','<button id="os13crop" class="s">Use supplied OS13 viewport</button><p class="hint">Preset excludes the fixed side HUDs (252–1332 at 1920×1080). Check the preview after any recording layout change. Unseen pixels remain transparent; video cannot reveal hidden rooms.</p><canvas id="pv"></canvas>')
s=s.replace("const seek=t=>", "$('os13crop').onclick=()=>{if(running||!reference)return;for(const[id,value]of Object.entries({cx:252/1920*reference.vw,cy:0,cw:1080/1920*reference.vw,ch:reference.vh}))$(id).value=Math.round(value);drawPrev()};\nconst seek=t=>")
a=s.index('function estimate(');b=s.index('const anchorPrep=',a)
s=s[:a]+'''function estimate(P,N,f,coarseOnly=false){
 // Keep independent coarse hypotheses: repeated tiles must not eliminate the
 // correct basin before finer pixels can distinguish walls and furnishings.
 const A=P.g16,B=N.g16,r=Math.ceil(f*Math.max(A.w,A.h)),stride=r>=6?3:1;
 const candidates=[{score:cost(A,B,0,0,1),x:0,y:0}];
 for(let y=-r;y<=r;y+=stride)for(let x=-r;x<=r;x+=stride)candidates.push({score:cost(A,B,x,y,2),x,y});
 candidates.sort((a,b)=>a.score-b.score||Math.hypot(a.x,a.y)-Math.hypot(b.x,b.y));
 const seeds=[];
 for(const q of candidates){if(q.score>=1e8)continue;if(seeds.every(p=>Math.hypot(p.x-q.x,p.y-q.y)>=2))seeds.push(q);if(seeds.length===4)break}
 if(!seeds.length)return[1e9,0,0];
 // Always evaluate stationary alignment, including when the coarse lattice
 // misses zero or periodic floor texture makes other translations score well.
 if(!seeds.some(q=>q.x===0&&q.y===0))seeds.push(candidates.find(q=>q.x===0&&q.y===0));
 let best=[1e9,0,0];
 const pick=(old,score,x,y)=>score<old[0]-.05||(Math.abs(score-old[0])<=.05&&x*x+y*y<old[1]*old[1]+old[2]*old[2])?[score,x,y]:old;
 for(const seed of seeds){
  let coarse=[seed.score,seed.x,seed.y];
  for(let y=seed.y-stride;y<=seed.y+stride;y++)for(let x=seed.x-stride;x<=seed.x+stride;x++)coarse=pick(coarse,cost(A,B,x,y,1),x,y);
  if(coarseOnly){best=pick(best,coarse[0],coarse[1]*16,coarse[2]*16);continue}
  let mid=[1e9,0,0];
  for(let y=coarse[2]*4-4;y<=coarse[2]*4+4;y++)for(let x=coarse[1]*4-4;x<=coarse[1]*4+4;x++)mid=pick(mid,cost(P.g4,N.g4,x,y,2),x,y);
  const scale=P.g1&&N.g1?1:2,a=scale===1?P.g1:P.g2,b=scale===1?N.g1:N.g2;
  for(let y=mid[2]*4/scale-3;y<=mid[2]*4/scale+3;y++)for(let x=mid[1]*4/scale-3;x<=mid[1]*4/scale+3;x++)best=pick(best,cost(a,b,x,y,Math.max(2,Math.floor(Math.min(a.w,a.h)/100))),x*scale,y*scale);
 }
 return best;
}
// Compute luminance once. Pool original valid samples directly at every scale
// to preserve the dark-mask weighting without four full RGB conversions.
function prep(d){
 const w=d.width,h=d.height,p=d.data,g=new Uint8Array(w*h),valid=new Uint8Array(w*h),lum=new Float32Array(w*h);
 for(let i=0;i<g.length;i++){const k=i*4;if(p[k+3]&&Math.max(p[k],p[k+1],p[k+2])>darkCut){valid[i]=1;lum[i]=p[k]*.299+p[k+1]*.587+p[k+2]*.114;g[i]=Math.round(lum[i])}}
 const pool=s=>{const W=Math.floor(w/s),H=Math.floor(h/s),v=new Uint8Array(W*H),a=new Uint8Array(W*H);
  for(let y=0;y<H;y++)for(let x=0;x<W;x++){let sum=0,n=0;for(let j=0;j<s;j++)for(let i=0;i<s;i++){const k=(y*s+j)*w+x*s+i;if(valid[k]){sum+=lum[k];n++}}const k=y*W+x;if(n>=Math.max(1,Math.ceil(s*s*.02))){v[k]=1;a[k]=Math.round(sum/n)}}return{g:a,valid:v,w:W,h:H}};
 return{g1:{g,valid,w,h},g2:pool(2),g4:pool(4),g16:pool(16)};
}
''' +s[b:]
s=s.replace('if(a.cnt[i]<255)a.cnt[i]++','if(a.cnt[i]<8)a.cnt[i]++')
s=s.replace('if(Math.max(p[k],p[k+1],p[k+2])<=darkCut)continue;','if(!p[k+3]||Math.max(p[k],p[k+1],p[k+2])<=darkCut)continue;')
s=s.replace('if(Math.max(p[k],p[k+1],p[k+2])>darkCut)good++','if(p[k+3]&&Math.max(p[k],p[k+1],p[k+2])>darkCut)good++')
s=s.replace('if(Math.max(r,gg,b)>darkCut){','if(p[k+3]&&Math.max(r,gg,b)>darkCut){')
s=s.replace('if(Math.max(r,g,b)<=darkCut)continue;visible++;','if(!data[k+3]||Math.max(r,g,b)<=darkCut)continue;visible++;')
s=s.replace("version:4,note:","version:5,reconstructionStatus:'Observed pixels only; registration and floor assignments require review',viewport:reference?{...crop(),referenceWidth:reference.vw,referenceHeight:reference.vh}:null,note:")
p.write_text(s,encoding='utf-8')
