exec(open('tmp/os13-map-reference/inspect.py').read().split('out=Image')[0])
for z in range(2,10):
 pts=[(x,y) for (x,y,l),k in grid.items() if l==z and k in ('i','d','s')];x1=min(x for x,y in pts);x2=max(x for x,y in pts);y1=min(y for x,y in pts);y2=min(max(y for x,y in pts),160)
 print('\nDECK',z,'x',x1,x2)
 print('    '+''.join(str(x//10%10) for x in range(x1,x2+1)));print('    '+''.join(str(x%10) for x in range(x1,x2+1)))
 for y in range(y2,y1-1,-1):print(f'{y:3} '+''.join({'i':'#','d':'.','s':'+','a':' ','N':' ','M':' '}.get(grid.get((x,y,z),'a'),grid.get((x,y,z),' ')) for x in range(x1,x2+1)))
