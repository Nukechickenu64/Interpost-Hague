from PIL import Image
from pathlib import Path
import cv2, re, numpy as np
scene=cv2.imread('C:/Users/nukec/AppData/Local/Temp/codex-clipboard-8b4cec8a-f42b-46fc-b29a-becd46716cae.png',0)
patches=[scene[355:402,344:395], scene[205:226,195:219], scene[304:328,431:461], scene[407:445,345:395]]
scales=[0.88,0.90,0.92,1]
files=list(Path('icons/os13').rglob('*.dmi'))+[Path('icons/obj/stairs.dmi'),Path('icons/obj/sstairs.dmi')]
ranks=[[] for i in patches]
for path in files:
 im=Image.open(path)
 meta=im.info.get('Description','')
 dims=[int(n) for n in re.findall(r'^\s*(?:width|height) = (\d+)',meta,re.M)]
 if len(dims)!=2:continue
 w,h=dims
 a=np.asarray(im.convert('L'))
 names=[]
 for s in meta.split('state = ')[1:]:
  names.extend([s.split('"')[1]]*int(re.search(r'dirs = (\d+)',s)[1])*int(re.search(r'frames = (\d+)',s)[1]))
 for k,patch in enumerate(patches):
  for scale in scales:
   p=cv2.resize(patch,None,fx=scale,fy=scale,interpolation=cv2.INTER_AREA)
   if any(l>r for l,r in zip(p.shape,a.shape)):continue
   _, v, _, (x,y)=cv2.minMaxLoc(cv2.matchTemplate(a,p,cv2.TM_CCOEFF_NORMED))
   idx=y//h*(im.width//w)+x//w
   ranks[k].append((round(v,3),str(path),names[idx] if idx<len(names) else '?',(x%w,y%h)))
for r in ranks:
 print(sorted(set(r),reverse=True)[:10])
