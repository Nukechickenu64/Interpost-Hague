from pathlib import Path
import re
from PIL import Image,ImageDraw
s=Path('os13.dmm').read_text(); defs=dict(re.findall(r'^"([A-Za-z]+)" = \((.*?)\)\s*$',s,re.M|re.S)); grid={}
for b in re.finditer(r'\((\d+),(\d+),(\d+)\) = \{"(.*?)"\}',s,re.S):
 x,y,z=map(int,b.group(1,2,3)); rows=b[4].strip().splitlines()
 for j,row in enumerate(rows):
  for i,k in enumerate(row):grid[x+i,y+len(rows)-1-j,z]=k
out=Image.new('RGB',(1000,800),'#101019'); d=ImageDraw.Draw(out)
for z in range(1,11):
 pts=[(x,y) for (x,y,l),k in grid.items() if l==z and k!='a']; print(z,len(pts), (min(x for x,y in pts),min(y for x,y in pts),max(x for x,y in pts),max(y for x,y in pts)) if pts else None)
 ox=((z-1)%5)*200;oy=((z-1)//5)*400
 for (x,y,l),k in grid.items():
  if l!=z or k=='a':continue
  col={'i':'#eeeeee','d':'#707070','s':'#936638','N':'#323255','M':'#323255','e':'#ff3333','A':'#33ff33','V':'#ffff33','v':'#ff33ff','T':'#33ffff','L':'#33ffff'}.get(k,'red')
  d.point((ox+x,oy+220-y),fill=col)
 d.text((ox+8,oy+8),f'DECK {z}',fill='white')
out.save('tmp/os13-map-reference/template.png')
