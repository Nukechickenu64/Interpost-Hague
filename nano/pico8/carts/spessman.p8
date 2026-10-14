pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

--spessman delivery
--catch cargo crates, dodge the pies

function _init()
  px=64
  lives=3
  score=0
  items={}
  timer=8
  gameover=false
  flash=0
end

function spawn()
  local n=rnd(2)
  if n==0 then
    add(items,{x=rnd(120),y=-6,v=1.2+rnd(1.4),k=0})
  elseif n==1 then
    add(items,{x=rnd(120),y=-6,v=0.8+rnd(1.6),k=1})
  end
end

function _update()
  if gameover then return end

  if btn(0) then px=px-2 end
  if btn(1) then px=px+2 end
  px=max(8,min(120,px))

  timer=timer-1
  if timer<=0 then
    spawn()
    timer=80
    if rnd(10)<3 then
      spawn()
    end
  end

  for i=#items,1,-1 do
    local o=items[i]
    o.y=o.y+o.v
    if o.k==0 and abs(o.x-px)<8 and o.y>116 and o.y<130 then
      del(items,i)
      score=score+1
      flash=6
    elseif o.y>132 then
      del(items,i)
      if o.k==0 then
        lives=lives-1
        flash=12
        if lives<=0 then
          gameover=true
          gpio(0,score)
        end
      end
    end
  end
end

function _draw()
  cls(0)

  --hud
  print("score "..score,2,2,7)
  print("lives "..lives,88,2,7)

  --delivery guy
  rectfill(px-6,116,px+6,124,11)
  rect(px-2,112,px+2,114,7)
  -- hard hat
  rectfill(px-4,106,px+4,108,10)
  rect(px-2,103,px+2,105,10)
  rectfill(px-2,104,px+2,104,7)

  --items
  for i=1,#items do
    local o=items[i]
    if o.k==0 then
      rectfill(o.x-4,o.y-4,o.x+4,o.y+4,9)
      rect(o.x-4,o.y-4,o.x+4,o.y+4,1)
    else
      circfill(o.x,o.y,4,8)
      circ(o.x,o.y,4,4)
    end
  end

  --flash
  if flash>0 then
    rectfill(0,0,127,3,11)
    flash=flash-1
  end

  if gameover then
    rectfill(20,48,108,78,0)
    rect(20,48,108,78,7)
    print("shift over",40,56,8)
    print("score "..score,44,66,7)
  end
end

__gfx__
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0077000000000000000000000000000000000000000000000000000000000000
0077000000000000000000000000000000000000000000000000000000000000
0077000000000000000000000000000000000000000000000000000000000000
0707700000000000000000000000000000000000000000000000000000000000
0770770000000000000000000000000000000000000000000000000000000000
0770770000000000000000000000000000000000000000000000000000000000
0077000000000000000000000000000000000000000000000000000000000000
0077000000000000000000000000000000000000000000000000000000000000