pico-8 cartridge // http://www.pico-8.com
version 32
__lua__

--breakout-8
--space brick smasher for the station janitor

function _init()
  px=64
  py=120
  bx=64
  by=90
  bvx=1.5
  bvy=-2
  lives=3
  score=0
  bricks={}
  for y=0,3 do
    for x=0,15 do
      if (x+y)%2==0 then
        bricks[x+y*16+1]=8
      else
        bricks[x+y*16+1]=12
      end
    end
  end
  gameover=false
  won=false
end

function _update()
  if gameover then return end

  if btn(0) then px=px-3 end
  if btn(1) then px=px+3 end
  px=max(8,min(120,px))

  bx=bx+bvx
  by=by+bvy

  if bx<2 or bx>126 then bvx=-bvx end
  if by<2 then
    bvy=-bvy
    by=2
  end

  if by>126 then
    lives=lives-1
    bx=64
    by=90
    bvx=1.5
    bvy=-2
    if lives<=0 then
      gameover=true
      gpio(0,score)
    end
  end

  if by>116 and by<126 and abs(bx-px)<9 and bvy>0 then
    bvy=-2
    bvx=(bx-px)*0.25
    by=116
  end

  local c=flr(bx/8)
  local r=flr(by/8)
  if r>=0 and r<4 and c>=0 and c<16 then
    local i=r*16+c+1
    if bricks[i]>0 then
      bricks[i]=0
      score=score+1
      if by%8<4 then
        bvy=-abs(bvy)
      else
        bvy=abs(bvy)
      end
    end
  end

  local left=0
  for i=1,64 do
    if bricks[i]>0 then left=left+1 end
  end
  if left==0 then
    gameover=true
    won=true
    gpio(0,score)
  end
end

function _draw()
  cls(0)

  print("score "..score,2,2,7)
  print("lives "..lives,88,2,7)

  for i=1,64 do
    if bricks[i]>0 then
      local r=flr((i-1)/16)
      local c=(i-1)%16
      rectfill(c*8+1,r*8+1,c*8+7,r*8+7,bricks[i])
    end
  end

  rectfill(px-8,py-3,px+8,py-1,11)
  rect(px-8,py-3,px+8,py-1,7)

  circfill(bx,by,2,7)

  if gameover then
    rectfill(2,54,126,74,0)
    rect(2,54,126,74,7)
    if won then
      print("shift cleared",36,58,11)
    else
      print("game over",44,58,8)
    end
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
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000