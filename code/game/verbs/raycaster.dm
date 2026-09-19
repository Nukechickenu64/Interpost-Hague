/client/verb/play_raycaster()
	set category = "OOC"
	set name = "Play Raycaster"
	set desc = "Open a 3D rendering of nearby map tiles."

	if(!mob || !isturf(mob.loc))
		to_chat(src, "<span class='warning'>You need to be standing on a map tile to use the raycaster.</span>")
		return

	var/turf/origin = get_turf(mob)
	var/radius = 15
	var/list/map_rows = list()
	for(var/y = origin.y + radius, y >= origin.y - radius, y--)
		var/row = ""
		for(var/x = origin.x - radius, x <= origin.x + radius, x++)
			var/turf/T = locate(x, y, origin.z)
			var/blocked = !T || T.density
			if(!blocked)
				for(var/atom/movable/A in T)
					if(A.density)
						blocked = TRUE
						break
			row += blocked ? "1" : "0"
		map_rows += row

	var/map_text = jointext(map_rows, "|")
	var/center = radius + 0.5
	var/page = {"
<!doctype html><html><head><title>Map Raycaster</title><style>
html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#111;color:#f4dfb0;font-family:Verdana,sans-serif}canvas{display:block;width:100%;height:100%;image-rendering:pixelated}#hud{position:fixed;left:12px;top:10px;text-shadow:2px 2px #000;font-size:12px;line-height:1.5;pointer-events:none}#status{color:#fa8}
</style></head><body><canvas id='view' width='480' height='300'></canvas><div id='hud'>LOCAL MAP RAYCASTER<br><span id='status'>WASD / ARROWS: MOVE AND TURN</span></div><script>
(function(){var canvas=document.getElementById('view'),ctx=canvas.getContext('2d'),rows='[map_text]'.split('|'),size=rows.length,player={x:[center],y:[center],a:0},left=false,right=false,forward=false,backward=false,fov=Math.PI/3,depth=15,walk=2.7,turn=2.2,last=0;function wall(x,y){var col=Math.floor(x),row=Math.floor(y),mapRow=rows.slice(row,row+1).pop();return row<0||col<0||row>=size||col>=mapRow.length||mapRow.charAt(col)==='1';}function move(distance){var nextX=player.x+Math.cos(player.a)*distance,nextY=player.y+Math.sin(player.a)*distance;if(!wall(nextX,player.y))player.x=nextX;if(!wall(player.x,nextY))player.y=nextY;}function draw(){var width=canvas.width,height=canvas.height;ctx.fillStyle='#1d2731';ctx.fillRect(0,0,width,height/2);ctx.fillStyle='#302722';ctx.fillRect(0,height/2,width,height/2);for(var column=0;column<width;column+=2){var ray=player.a-fov/2+column/width*fov,step=.025,distance=0;while(distance<depth&&!wall(player.x+Math.cos(ray)*distance,player.y+Math.sin(ray)*distance))distance+=step;var corrected=distance*Math.cos(ray-player.a),line=Math.min(height,height/(corrected||.01)),shade=Math.max(20,190-distance*13);ctx.fillStyle='rgb('+shade+','+Math.max(10,shade-45)+','+Math.max(8,shade-80)+')';ctx.fillRect(column,(height-line)/2,2,line);}ctx.fillStyle='#f4dfb0';ctx.fillRect(width/2-1,height/2-6,2,12);ctx.fillRect(width/2-6,height/2-1,12,2);}function frame(time){var elapsed=Math.min((time-last)/1000,.05);last=time;if(left)player.a-=turn*elapsed;if(right)player.a+=turn*elapsed;if(forward)move(walk*elapsed);if(backward)move(-walk*elapsed);draw();requestAnimationFrame(frame);}function key(event,down){if(event.keyCode===65||event.keyCode===37)left=down;if(event.keyCode===68||event.keyCode===39)right=down;if(event.keyCode===87||event.keyCode===38)forward=down;if(event.keyCode===83||event.keyCode===40)backward=down;if(event.keyCode>=37&&event.keyCode<=40)event.preventDefault();}document.addEventListener('keydown',function(event){key(event,true);});document.addEventListener('keyup',function(event){key(event,false);});draw();requestAnimationFrame(frame);})();
</script></body></html>
"}

	src << browse(page, "window=raycaster;size=960x600;can_resize=1;can_minimize=1")