from pathlib import Path
import subprocess,imageio_ffmpeg
from PIL import Image,ImageDraw
videos=list(Path('D:/os13archive').glob('Lifeweb OS13 *.mp4'))
sheet=Image.new('RGB',(960,620)); draw=ImageDraw.Draw(sheet)
for i,v in enumerate(videos):
 p=Path('tmp/video-map')/f'source-{i}.jpg'
 subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-loglevel','error','-ss','600','-i',str(v),'-frames:v','1','-y',str(p)],check=True)
 im=Image.open(p); im.thumbnail((480,270));x=i%2*480;y=i//2*310;sheet.paste(im,(x,y+30));draw.text((x,y),v.name[13:65],fill='white')
sheet.save('tmp/video-map/sources.jpg')
