import zipfile,json,io
from PIL import Image,ImageDraw
z=zipfile.ZipFile(r'D:\Downloads\all_z_layers(2).zip');m=json.loads(z.read('map_all_z.json'));out=Image.new('RGB',(1200,900),'#222222');d=ImageDraw.Draw(out)
for i,n in enumerate([1,2,3,11,20,38,40,54,55,60,71,78]):
 im=Image.open(io.BytesIO(z.read(f'master_map_z{n}.png')));im.thumbnail((300,260));x=i%4*300;y=i//4*300;out.paste(im,(x,y+30),im);d.text((x,y),f'Region {n}',fill='white')
out.save('tmp/video-map/export-survey.jpg');print(json.dumps(m['levels'][2],indent=2)[:2000])
