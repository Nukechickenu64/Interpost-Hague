exec(open('tools/os13_map/inspect_map.py').read().split('for z in range(2,10):')[0].replace("ROOT=Path(__file__).resolve().parents[2]","ROOT=Path.cwd()"))
import heapq
for z,start in [(3,(107,127,3)),(5,(129,128,5)),(5,(126,116,5)),(6,(95,135,6)),(7,(135,129,7))]:
 dist={start:0};prev={};todo=[(0,start)];target=(116,122,z)
 while todo:
  cost,p=heapq.heappop(todo)
  if p==target:break
  if dist[p]!=cost:continue
  for q in neighbors(p):
   c=grid.get(q,'')
   if '/area/os13' not in c or any(b in c for b in blocked_prefixes):continue
   weight=1 if '/floor' in c else 50 if '/wall' in c else 9999
   nc=cost+weight
   if nc<dist.get(q,999999):dist[q]=nc;prev[q]=p;heapq.heappush(todo,(nc,q))
 route=[];p=target
 while p!=start and p in prev:
  if '/wall' in grid[p]:route.append(p)
  p=prev[p]
 print(start,'wall cuts',route)
