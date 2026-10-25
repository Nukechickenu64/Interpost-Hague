from pathlib import Path
import subprocess,imageio_ffmpeg
videos=list(Path('D:/os13archive').glob('Lifeweb OS13 *.mp4'))
for i,v in enumerate(videos):
 for t in [1043.1,1043.25]:
  subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-loglevel','error','-ss',str(t),'-i',str(v),'-frames:v','1','-y',f'tmp/video-map/motion-{i}-{t}.png'],check=True)
p=Path('artifacts/os13-video-map/test.cjs');s=p.read_text();s=s.replace('return results;});', '''
const patch=new ImageData(256,256);for(let y=20;y<55;y++)for(let x=20;x<55;x++)patch.data.set(d.data.subarray((y*256+x)*4,(y*256+x)*4+4),(y*256+x)*4);
check('isolated matching patch rejected',!motionSupport(prep(patch),prep(patch),0,0).ok);
check('automatic joins opt in',!document.getElementById('autojoin').checked&&!document.getElementById('autoreconcile').checked);
reference={vw:1920,vh:1080};document.getElementById('os13crop').click();check('HUD excluded',crop().x===256&&crop().x+crop().w===1324);
for(let i=0;i<4;i++){const frames=[];for(const t of ['1043.1','1043.25']){const im=new Image();im.src='../../tmp/video-map/motion-'+i+'-'+t+'.png';await im.decode();const c=document.createElement('canvas');c.width=1068;c.height=1080;const ctx=c.getContext('2d');ctx.drawImage(im,256,0,1068,1080,0,0,1068,1080);frames.push(prep(ctx.getImageData(0,0,1068,1080)))}
 const forward=estimate(frames[0],frames[1],.24),reverse=estimate(frames[1],frames[0],.24);
 check('video '+i+' moving pair reversible or withheld',forward[0]>=1e8||reverse[0]>=1e8||(Math.abs(forward[1]+reverse[1])<=2&&Math.abs(forward[2]+reverse[2])<=2),{forward,reverse});}
return results;});''');p.write_text(s)
