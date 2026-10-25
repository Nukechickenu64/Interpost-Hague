const {chromium}=require('C:/Users/nukec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path'),assert=require('assert');
(async()=>{const browser=await chromium.launch({channel:'msedge',headless:true,args:['--allow-file-access-from-files']});try{
const page=await browser.newPage();await page.goto('file:///'+path.resolve('artifacts/os13-video-map/studio.html').replaceAll('\\','/'));
const result=await page.evaluate(async()=>{
const results=[];function check(name,condition,detail){results.push({name,pass:!!condition,detail});if(!condition)throw Error(JSON.stringify(results))}
const d=new ImageData(256,256);let seed=42;for(let i=0;i<d.data.length;i+=4){seed=(Math.imul(seed,1664525)+1013904223)>>>0;d.data[i]=30+seed%170;d.data[i+1]=40+(seed>>>8)%150;d.data[i+2]=50+(seed>>>16)%140;d.data[i+3]=255}
const p=prep(d);for(const s of [1,2,4,16]){const original=gray(d,s),actual=p['g'+s];check('pyramid '+s,original.g.every((v,i)=>Math.abs(v-actual.g[i])<=1)&&original.valid.every((v,i)=>v===actual.valid[i]))}
for(const [dx,dy]of [[0,0],[17,-11],[-24,32]]){const n=new ImageData(256,256);for(let y=0;y<256;y++)for(let x=0;x<256;x++){const X=x+dx,Y=y+dy;if(X>=0&&Y>=0&&X<256&&Y<256)n.data.set(d.data.subarray((Y*256+X)*4,(Y*256+X)*4+4),(y*256+x)*4)}const motion=estimate(p,prep(n),.24);check('translation '+dx+','+dy,motion[1]===dx&&motion[2]===dy,motion)}
const blank=new ImageData(256,256);check('no evidence',estimate(prep(blank),prep(blank),.24)[0]>=1e8);
const map={chunks:new Map(),b:{x0:10,y0:10,x1:0,y1:0},W:256,H:256};const one=new ImageData(1,1);one.data.set([100,50,50,255]);for(let i=0;i<300;i++)paint(map,one,0,0,30);one.data.set([50,150,50,255]);for(let i=0;i<9;i++)paint(map,one,0,0,30);check('stationary transient replaced',pixel(map,0,0)[1]===150);
for(let i=0;i<4;i++){const im=new Image();im.src='../../tmp/video-map/source-'+i+'.jpg';await im.decode();const c=document.createElement('canvas');c.width=c.height=432;const ctx=c.getContext('2d');ctx.drawImage(im,252,0,1080,1080,0,0,432,432);const frame=ctx.getImageData(0,0,432,432),motion=estimate(prep(frame),prep(frame),.24);check('recording '+i+' stationary',motion[1]===0&&motion[2]===0,motion)}
const patch=new ImageData(256,256);for(let y=20;y<55;y++)for(let x=20;x<55;x++)patch.data.set(d.data.subarray((y*256+x)*4,(y*256+x)*4+4),(y*256+x)*4);
check('isolated matching patch rejected',!motionSupport(prep(patch),prep(patch),0,0).ok);
check('automatic joins opt in',!document.getElementById('autojoin').checked&&!document.getElementById('autoreconcile').checked);
reference={vw:1920,vh:1080};document.getElementById('os13crop').click();check('HUD excluded',crop().x===256&&crop().x+crop().w===1324);
for(let i=0;i<4;i++){const frames=[];for(const t of ['1043.1','1043.25']){const im=new Image();im.src='../../tmp/video-map/motion-'+i+'-'+t+'.png';await im.decode();const c=document.createElement('canvas');c.width=1068;c.height=1080;const ctx=c.getContext('2d');ctx.drawImage(im,256,0,1068,1080,0,0,1068,1080);frames.push(prep(ctx.getImageData(0,0,1068,1080)))}
 const forward=estimate(frames[0],frames[1],.24),reverse=estimate(frames[1],frames[0],.24);
 check('video '+i+' moving pair reversible or withheld',forward[0]>=1e8||reverse[0]>=1e8||(Math.abs(forward[1]+reverse[1])<=2&&Math.abs(forward[2]+reverse[2])<=2),{forward,reverse});}
return results;});
fs.writeFileSync('artifacts/os13-video-map/test-results.json',JSON.stringify(result,null,2));console.log(JSON.stringify(result,null,2));
}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
