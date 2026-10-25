from PIL import Image,ImageDraw
from pathlib import Path
import re,math
paths=['icons/os13/turf/turf/wallw.dmi','icons/os13/turf/turf/walls3.dmi','icons/os13/turf/turf/wwalls.dmi','icons/os13/turf/turf/wall.dmi']
for p in paths:
 im=Image.open(p).convert('RGBA');im.info=Image.open(p).info;meta=im.info.get('Description',''); w=int(re.search(r'width = (\d+)',meta)[1]);h=int(re.search(r'height = (\d+)',meta)[1]);states=re.split(r'\nstate = ',meta)[1:];out=Image.new('RGB',(1000,math.ceil(len(states)/10)*90),'#333333');d=ImageDraw.Draw(out);offset=0
 for i,s in enumerate(states):
  name=s.split('"')[1];dirs=int(re.search(r'dirs = (\d+)',s)[1]);frames=int(re.search(r'frames = (\d+)',s)[1]);tile=im.crop((offset%(im.width//w)*w,offset//(im.width//w)*h,offset%(im.width//w)*w+w,offset//(im.width//w)*h+h));tile.thumbnail((62,62));x=i%10*100;y=i//10*90;out.paste(tile,(x,y),tile);d.text((x,y+62),name[:17],fill='white');offset+=dirs*frames
 out.save('tmp/os13-map-reference/'+Path(p).stem+'-atlas.png');print(p,len(states),w,h)

