exec(open('tmp/os13-map-reference/inspect.py').read().split('out=Image')[0])
for z,y,x1,x2 in [(4,117,94,113),(9,139,122,130)]:print(z,y,[(x,grid[x,y,z]) for x in range(x1,x2+1)])
