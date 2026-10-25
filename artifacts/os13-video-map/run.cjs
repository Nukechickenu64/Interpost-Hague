const {chromium}=require('C:/Users/nukec/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path');
(async()=>{
const out=path.resolve('artifacts/os13-video-map');
const browser=await chromium.launch({channel:'msedge',headless:true,args:['--allow-file-access-from-files','--disable-background-timer-throttling']});
const page=await browser.newPage({acceptDownloads:true});
page.on('download',async d=>{await d.saveAs(path.join(out,d.suggestedFilename()));});
page.on('pageerror',e=>fs.appendFileSync(path.join(out,'errors.log'),e.stack+'\n'));
await page.goto('file:///'+out.replaceAll('\\','/')+'/studio.html');
const files=fs.readdirSync('D:/os13archive').filter(x=>x.startsWith('Lifeweb OS13 ')&&x.endsWith('.mp4')).map(x=>'D:/os13archive/'+x);
await page.locator('#file').setInputFiles(files);
await page.waitForFunction(()=>document.querySelector('#vid').videoWidth>0);
await page.evaluate(()=>{for(const [id,val] of Object.entries({cx:256,cy:0,cw:1068,ch:1080,step:0.2,ms:8192,maxz:100}))document.getElementById(id).value=val; document.getElementById('autoreconcile').checked=false;});
await page.locator('#run').click();
while(true){await page.waitForTimeout(10000);const state=await page.evaluate(()=>({running,log:document.getElementById('log').textContent,regions:levels.length,stats:lastStats}));fs.writeFileSync(path.join(out,'progress.json'),JSON.stringify(state,null,2));console.log(state.log);if(!state.running)break;}
await page.locator('#diagnostics').click();
await page.locator('#allmasters').click();
await page.waitForFunction(()=>!document.getElementById('allmasters').disabled,{},{timeout:0});
await page.waitForTimeout(3000);
await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1});
