exec(open('tmp/os13-map-reference/inspect.py').read().split('out=Image')[0])
for z in range(2,10):
 im=Image.new('RGB',(1100,1050),'#101019');d=ImageDraw.Draw(im)
 for (x,y,l),k in grid.items():
  if l!=z or k in ('a','N','M') or not(75<=x<=155 and 80<=y<=150):continue
  px=(x-75)*13;py=(150-y)*13
  col={'i':'#aaaaaa','d':'#444444','s':'#715433','e':'#ff3333','A':'#33ff33','V':'#ffff33','v':'#ff33ff','T':'#33ffff','L':'#33ffff'}.get(k,'red')
  d.rectangle((px,py,px+11,py+11),fill=col)
  if k not in ('i','d','s'):d.text((px,py),k,fill='black')
 for x in range(75,156,5):d.text(((x-75)*13,930),str(x),fill='white')
 for y in range(80,151,5):d.text((1050,(150-y)*13),str(y),fill='white')
 d.text((10,970),f'Deck {z}',fill='white');im.save(f'tmp/os13-map-reference/deck-{z}.png')
