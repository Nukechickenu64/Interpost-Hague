/*
 * First-person renderer for the BYOND map pane.
 *
 * The game supplies flattened BYOND appearances as browser resources. Floors
 * and walls are sampled as real textures, movable objects are colour-voxelized
 * from their icon, and mobs remain directional sprite billboards.
 */
(function () {
	"use strict";

	var canvas = document.getElementById("shock3d-canvas");
	var context = canvas.getContext && canvas.getContext("2d");
	var status = document.getElementById("status");
	var scene = null;
	var fov = Math.PI * 0.36;
	var imageCache = {};
	var voxelCache = {};
	var depthBuffer = [];
	var cameraHeight = 0.5;

	function byondCommand(command) {
		window.location = "byond://winset?command=" + encodeURIComponent(command);
	}

	function resize() {
		var width = Math.max(1, document.documentElement.clientWidth || document.body.clientWidth || 640);
		var height = Math.max(1, document.documentElement.clientHeight || document.body.clientHeight || 480);
		if (canvas.width !== width || canvas.height !== height) {
			canvas.width = width;
			canvas.height = height;
		}
	}

	function directionAngle(direction) {
		switch (direction) {
		case 1: return -Math.PI / 2; // NORTH
		case 2: return Math.PI / 2;  // SOUTH
		case 4: return 0;            // EAST
		case 8: return Math.PI;      // WEST
		case 5: return -Math.PI / 4;
		case 6: return Math.PI / 4;
		case 9: return -3 * Math.PI / 4;
		case 10: return 3 * Math.PI / 4;
		default: return -Math.PI / 2;
		}
	}

	function clamp(value, lower, upper) {
		return Math.max(lower, Math.min(upper, value));
	}

	function isWall(mapX, mapY) {
		if (!scene || mapY < 0 || mapY >= scene.cells.length || mapX < 0 || mapX >= scene.cells[mapY].length) {
			return true;
		}
		return scene.cells[mapY].charAt(mapX) !== "0";
	}

	function textureAt(mapX, mapY) {
		if (!scene || !scene.textures || mapY < 0 || mapY >= scene.textures.length || !scene.textures[mapY]) {
			return "";
		}
		return scene.textures[mapY][mapX] || "";
	}

	function isHole(mapX, mapY) {
		if (!scene || !scene.holes || mapY < 0 || mapY >= scene.holes.length) {
			return false;
		}
		return scene.holes[mapY].charAt(mapX) === "1";
	}

	function belowTextureAt(mapX, mapY) {
		if (!scene || !scene.belowTextures || mapY < 0 || mapY >= scene.belowTextures.length || !scene.belowTextures[mapY]) {
			return "";
		}
		return scene.belowTextures[mapY][mapX] || "";
	}

	function resourceImage(resource) {
		if (!resource) {
			return null;
		}
		if (imageCache[resource]) {
			return imageCache[resource];
		}

		var record = {
			image: new Image(),
			ready: false,
			failed: false,
			pixels: null
		};
		record.image.onload = function () {
			record.ready = true;
			voxelCache[resource] = null;
			draw();
		};
		record.image.onerror = function () {
			record.failed = true;
		};
		imageCache[resource] = record;
		record.image.src = resource;
		if (record.image.complete && record.image.width) {
			record.ready = true;
		}
		return record;
	}

	function resourcePixels(resource) {
		var record = resourceImage(resource);
		if (!record || !record.ready || record.failed) {
			return null;
		}
		if (record.pixels) {
			return record.pixels;
		}

		var scratch = document.createElement("canvas");
		scratch.width = Math.max(1, record.image.width);
		scratch.height = Math.max(1, record.image.height);
		var scratchContext = scratch.getContext("2d");
		try {
			scratchContext.drawImage(record.image, 0, 0);
			record.pixels = {
				data: scratchContext.getImageData(0, 0, scratch.width, scratch.height).data,
				width: scratch.width,
				height: scratch.height
			};
		} catch (error) {
			record.failed = true;
		}
		return record.pixels;
	}

	function lightingAt(lightingGrid, mapX, mapY, distance, maxDistance) {
		var tileLight = [0.06, 0.07, 0.08];
		if (lightingGrid && lightingGrid[mapY] && lightingGrid[mapY][mapX]) {
			tileLight = lightingGrid[mapY][mapX];
		}
		var distanceFalloff = Math.max(0.14, 1 - distance / Math.max(1, maxDistance + 2));
		return [
			Math.max(0.025, (tileLight[0] || 0) * distanceFalloff),
			Math.max(0.025, (tileLight[1] || 0) * distanceFalloff),
			Math.max(0.025, (tileLight[2] || 0) * distanceFalloff)
		];
	}

	function sceneLightingAt(mapX, mapY, distance, maxDistance) {
		return lightingAt(scene && scene.lighting, mapX, mapY, distance, maxDistance);
	}

	function belowLightingAt(mapX, mapY, distance, maxDistance) {
		return lightingAt(scene && scene.belowLighting, mapX, mapY, distance, maxDistance);
	}

	function darkenLight(light, amount) {
		return [light[0] * amount, light[1] * amount, light[2] * amount];
	}

	function lightColour(light) {
		return "rgb(" + Math.floor(clamp(light[0], 0, 1) * 255) + "," + Math.floor(clamp(light[1], 0, 1) * 255) + "," + Math.floor(clamp(light[2], 0, 1) * 255) + ")";
	}

	function lightStrength(light) {
		return (light[0] + light[1] + light[2]) / 3;
	}

	function textureColour(resource, u, v, light) {
		if (typeof light === "number") {
			light = [light, light, light];
		}
		var pixels = resourcePixels(resource);
		if (!pixels) {
			return "rgb(" + Math.floor(42 * light[0]) + "," + Math.floor(98 * light[1]) + "," + Math.floor(90 * light[2]) + ")";
		}

		var wrappedU = u - Math.floor(u);
		var wrappedV = v - Math.floor(v);
		var x = clamp(Math.floor(wrappedU * pixels.width), 0, pixels.width - 1);
		var y = clamp(Math.floor(wrappedV * pixels.height), 0, pixels.height - 1);
		var index = (y * pixels.width + x) * 4;
		var alpha = pixels.data[index + 3] / 255;
		if (!alpha) {
			return "rgb(4,7,7)";
		}
		return "rgb(" + Math.floor(pixels.data[index] * light[0]) + "," + Math.floor(pixels.data[index + 1] * light[1]) + "," + Math.floor(pixels.data[index + 2] * light[2]) + ")";
	}

	function drawBackdrop(width, height) {
		var horizon = Math.floor(height * 0.5);
		var sky = context.createLinearGradient(0, 0, 0, horizon);
		sky.addColorStop(0, "#02090b");
		sky.addColorStop(1, "#173132");
		context.fillStyle = sky;
		context.fillRect(0, 0, width, horizon);

		var floor = context.createLinearGradient(0, horizon, 0, height);
		floor.addColorStop(0, "#25291e");
		floor.addColorStop(1, "#030504");
		context.fillStyle = floor;
		context.fillRect(0, horizon, width, height - horizon);
	}

	function drawFloorPlane(posX, posY, angle, width, height, floorHeight, textureLookup, lightingLookup, shouldDrawTile) {
		var horizon = Math.floor(height * 0.5);
		var focalLength = width / (2 * Math.tan(fov / 2));
		var pixelSize = Math.max(2, Math.floor(width / 220));
		var maxDistance = (scene.radius || 7) + 1.5;

		for (var y = horizon + pixelSize; y < height; y += pixelSize) {
			var rowDistance = (cameraHeight - floorHeight) * focalLength / Math.max(1, y - horizon);
			if (rowDistance > maxDistance) {
				continue;
			}
			for (var x = 0; x < width; x += pixelSize) {
				var rayAngle = angle - fov / 2 + ((x + pixelSize * 0.5) / width) * fov;
				var worldX = posX + Math.cos(rayAngle) * rowDistance;
				var worldY = posY + Math.sin(rayAngle) * rowDistance;
				var tileX = Math.floor(worldX);
				var tileY = Math.floor(worldY);
				if (!shouldDrawTile(tileX, tileY)) {
					continue;
				}
				var floorTexture = textureLookup(tileX, tileY);
				if (!floorTexture) {
					continue;
				}
				context.fillStyle = textureColour(floorTexture, worldX, worldY, lightingLookup(tileX, tileY, rowDistance, maxDistance));
				context.fillRect(x, y, pixelSize, pixelSize);
			}
		}
	}

	function drawTexturedFloors(posX, posY, angle, width, height) {
		// Draw the deck below first. The current deck is then composited over it,
		// skipping floorless/open turfs so a shaft reveals the lower z-level.
		drawFloorPlane(posX, posY, angle, width, height, -1, belowTextureAt, belowLightingAt, isHole);
		drawFloorPlane(posX, posY, angle, width, height, 0, textureAt, sceneLightingAt, function (mapX, mapY) {
			return !isHole(mapX, mapY);
		});
	}

	function castRay(posX, posY, rayX, rayY) {
		var mapX = Math.floor(posX);
		var mapY = Math.floor(posY);
		var deltaX = rayX === 0 ? 1e30 : Math.abs(1 / rayX);
		var deltaY = rayY === 0 ? 1e30 : Math.abs(1 / rayY);
		var stepX;
		var stepY;
		var sideX;
		var sideY;
		var side = 0;
		var guard = 0;

		if (rayX < 0) {
			stepX = -1;
			sideX = (posX - mapX) * deltaX;
		} else {
			stepX = 1;
			sideX = (mapX + 1 - posX) * deltaX;
		}
		if (rayY < 0) {
			stepY = -1;
			sideY = (posY - mapY) * deltaY;
		} else {
			stepY = 1;
			sideY = (mapY + 1 - posY) * deltaY;
		}

		while (!isWall(mapX, mapY) && guard++ < 64) {
			if (sideX < sideY) {
				sideX += deltaX;
				mapX += stepX;
				side = 0;
			} else {
				sideY += deltaY;
				mapY += stepY;
				side = 1;
			}
		}

		var distance = Math.max(0.08, side === 0 ? sideX - deltaX : sideY - deltaY);
		var textureOffset = side === 0 ? posY + distance * rayY : posX + distance * rayX;
		textureOffset -= Math.floor(textureOffset);
		if ((side === 0 && rayX > 0) || (side === 1 && rayY < 0)) {
			textureOffset = 1 - textureOffset;
		}
		return {
			distance: distance,
			mapX: mapX,
			mapY: mapY,
			side: side,
			textureOffset: textureOffset
		};
	}

	function drawWalls(posX, posY, angle, width, height) {
		var columnWidth = Math.max(1, Math.floor(width / 320));
		depthBuffer = new Array(width);
		for (var x = 0; x < width; x += columnWidth) {
			var rayAngle = angle - fov / 2 + (x / width) * fov;
			var hit = castRay(posX, posY, Math.cos(rayAngle), Math.sin(rayAngle));
			var perpendicularDistance = hit.distance * Math.cos(rayAngle - angle);
			var lineHeight = Math.min(height * 3, height / perpendicularDistance);
			var top = Math.floor((height - lineHeight) / 2);
			var light = sceneLightingAt(hit.mapX, hit.mapY, perpendicularDistance, 10);
			if (hit.side === 1) {
				light = darkenLight(light, 0.72);
			}

			var resource = textureAt(hit.mapX, hit.mapY);
			var record = resourceImage(resource);
			if (record && record.ready && !record.failed) {
				var sourceX = clamp(Math.floor(hit.textureOffset * record.image.width), 0, record.image.width - 1);
				context.drawImage(record.image, sourceX, 0, 1, record.image.height, x, top, columnWidth, Math.ceil(lineHeight));
				context.save();
				context.globalCompositeOperation = "multiply";
				context.fillStyle = lightColour(light);
				context.fillRect(x, top, columnWidth, Math.ceil(lineHeight));
				context.restore();
			} else {
				context.fillStyle = textureColour(resource, hit.textureOffset, 0.5, light);
				context.fillRect(x, top, columnWidth, Math.ceil(lineHeight));
			}

			for (var column = x; column < x + columnWidth && column < width; column++) {
				depthBuffer[column] = perpendicularDistance;
			}
		}
	}

	function wallDepthAt(screenX) {
		var column = clamp(Math.floor(screenX), 0, depthBuffer.length - 1);
		return depthBuffer[column] || 999;
	}

	function projectPoint(worldX, worldY, worldZ, posX, posY, angle, focalLength, horizon, width) {
		var dx = worldX - posX;
		var dy = worldY - posY;
		var depth = dx * Math.cos(angle) + dy * Math.sin(angle);
		if (depth <= 0.05) {
			return null;
		}
		var side = -dx * Math.sin(angle) + dy * Math.cos(angle);
		return {
			x: width * 0.5 + side * focalLength / depth,
			y: horizon - (worldZ - cameraHeight) * focalLength / depth,
			depth: depth
		};
	}

	function drawBillboard(entity, posX, posY, angle, width, height) {
		var resource = entity.sprite;
		var record = resourceImage(resource);
		if (!record || !record.ready || record.failed) {
			return;
		}

		var focalLength = width / (2 * Math.tan(fov / 2));
		var horizon = height * 0.5;
		var dx = entity.x - posX;
		var dy = entity.y - posY;
		var depth = dx * Math.cos(angle) + dy * Math.sin(angle);
		if (depth <= 0.1) {
			return;
		}
		var side = -dx * Math.sin(angle) + dy * Math.cos(angle);
		var spriteHeight = Math.min(height * 1.6, focalLength * 1.12 / depth);
		var spriteWidth = spriteHeight * record.image.width / Math.max(1, record.image.height);
		var screenX = width * 0.5 + side * focalLength / depth;
		var bottom = horizon + cameraHeight * focalLength / depth;
		var left = Math.floor(screenX - spriteWidth * 0.5);
		var right = Math.ceil(screenX + spriteWidth * 0.5);
		var top = Math.floor(bottom - spriteHeight);
		var visibleStart = null;
		var spriteLight = sceneLightingAt(Math.floor(entity.x), Math.floor(entity.y), depth, 10);
		var spriteAlpha = clamp(lightStrength(spriteLight) * 1.25, 0.1, 1);

		function drawSlice(start, end) {
			if (start === null || end <= start) {
				return;
			}
			var sourceLeft = (start - left) / spriteWidth * record.image.width;
			var sourceWidth = (end - start) / spriteWidth * record.image.width;
			context.save();
			context.globalAlpha = spriteAlpha;
			context.drawImage(record.image, sourceLeft, 0, sourceWidth, record.image.height, start, top, end - start, spriteHeight);
			context.restore();
		}

		for (var x = Math.max(0, left); x < Math.min(width, right); x++) {
			if (depth < wallDepthAt(x)) {
				if (visibleStart === null) {
					visibleStart = x;
				}
			} else if (visibleStart !== null) {
				drawSlice(visibleStart, x);
				visibleStart = null;
			}
		}
		drawSlice(visibleStart, Math.min(width, right));
	}

	function hasWords(text, words) {
		for (var i = 0; i < words.length; i++) {
			if (text.indexOf(words[i]) !== -1) {
				return true;
			}
		}
		return false;
	}

	function semanticModel(entity) {
		if (entity.model) {
			return entity.model;
		}
		var details = ((entity.name || "") + " " + (entity.description || "") + " " + (entity.type || "")).toLowerCase();
		if (hasWords(details, ["pipe", "cable", "wire", "hose", "duct", "conduit"])) { return "pipe"; }
		if (hasWords(details, ["table", "desk", "counter", "workbench", "altar"])) { return "table"; }
		if (hasWords(details, ["chair", "stool", "bench", "sofa", "throne"])) { return "chair"; }
		if (hasWords(details, ["bed", "cot", "gurney", "bunk", "mattress"])) { return "bed"; }
		if (hasWords(details, ["crate", "locker", "closet", "cabinet", "safe", "box", "chest", "vending"])) { return "container"; }
		if (hasWords(details, ["computer", "console", "terminal", "machine", "generator", "engine", "reactor", "fabricator", "printer", "dispenser", "server"])) { return "machine"; }
		if (hasWords(details, ["window", "grille", "railing", "fence", "barricade", "barrier"])) { return "barrier"; }
		if (hasWords(details, ["lamp", "light", "torch", "lantern", "beacon"])) { return "lamp"; }
		if (hasWords(details, ["plant", "tree", "bush", "flower", "mushroom", "grass", "vine"])) { return "plant"; }
		if (hasWords(details, ["gun", "rifle", "pistol", "sword", "knife", "axe", "spear", "hammer", "drill", "saw", "wrench", "tool"])) { return "tool"; }
		if (hasWords(details, ["book", "paper", "card", "clipboard", "disk", "coin", "plate", "sheet"])) { return "flat_item"; }
		return "sculpted";
	}

	function paletteFromPixels(pixels) {
		var bins = {};
		var bucketSize = 32;
		for (var y = 0; y < pixels.height; y += Math.max(1, Math.floor(pixels.height / 24))) {
			for (var x = 0; x < pixels.width; x += Math.max(1, Math.floor(pixels.width / 24))) {
				var index = (y * pixels.width + x) * 4;
				if (pixels.data[index + 3] < 80) {
					continue;
				}
				var red = Math.floor(pixels.data[index] / bucketSize) * bucketSize;
				var green = Math.floor(pixels.data[index + 1] / bucketSize) * bucketSize;
				var blue = Math.floor(pixels.data[index + 2] / bucketSize) * bucketSize;
				var key = red + ":" + green + ":" + blue;
				if (!bins[key]) {
					bins[key] = { count: 0, red: 0, green: 0, blue: 0 };
				}
				bins[key].count++;
				bins[key].red += pixels.data[index];
				bins[key].green += pixels.data[index + 1];
				bins[key].blue += pixels.data[index + 2];
			}
		}
		var palette = [];
		for (var colourKey in bins) {
			if (bins.hasOwnProperty(colourKey)) {
				var bucket = bins[colourKey];
				palette.push({
					count: bucket.count,
					colour: [Math.floor(bucket.red / bucket.count), Math.floor(bucket.green / bucket.count), Math.floor(bucket.blue / bucket.count)]
				});
			}
		}
		palette.sort(function (left, right) { return right.count - left.count; });
		var result = [];
		for (var i = 0; i < palette.length && i < 5; i++) {
			result.push(palette[i].colour);
		}
		return result.length ? result : [[116, 128, 132]];
	}

	function paletteColour(palette, index) {
		return palette[Math.abs(index) % palette.length];
	}

	function addVoxel(voxels, x, y, z, colour, size) {
		if (voxels.length >= 128) {
			return;
		}
		voxels.push({ x: x, y: y, z: z, colour: colour, size: size });
	}

	function addShellBox(voxels, palette, cellsX, cellsY, cellsZ, width, depth, height, centreZ, colourOffset) {
		var size = Math.min(width / cellsX, depth / cellsY, height / cellsZ) * 0.44;
		for (var z = 0; z < cellsZ; z++) {
			for (var y = 0; y < cellsY; y++) {
				for (var x = 0; x < cellsX; x++) {
					if (x !== 0 && x !== cellsX - 1 && y !== 0 && y !== cellsY - 1 && z !== 0 && z !== cellsZ - 1) {
						continue;
					}
					addVoxel(voxels, (x + 0.5) * width / cellsX - width * 0.5, (y + 0.5) * depth / cellsY - depth * 0.5, centreZ + (z + 0.5) * height / cellsZ - height * 0.5, paletteColour(palette, x + y * 3 + z + colourOffset), size);
				}
			}
		}
	}

	function addPlate(voxels, palette, cellsX, cellsY, width, depth, z, colourOffset) {
		var size = Math.min(width / cellsX, depth / cellsY, 0.07) * 0.46;
		for (var y = 0; y < cellsY; y++) {
			for (var x = 0; x < cellsX; x++) {
				addVoxel(voxels, (x + 0.5) * width / cellsX - width * 0.5, (y + 0.5) * depth / cellsY - depth * 0.5, z, paletteColour(palette, x + y + colourOffset), size);
			}
		}
	}

	function addColumn(voxels, palette, x, y, bottom, top, cells, colourOffset, radius) {
		for (var z = 0; z < cells; z++) {
			addVoxel(voxels, x, y, bottom + (z + 0.5) * (top - bottom) / cells, paletteColour(palette, z + colourOffset), radius);
		}
	}

	function buildSculptedModel(pixels) {
		var gridWidth = 9;
		var gridHeight = 11;
		var cells = [];
		for (var gy = 0; gy < gridHeight; gy++) {
			cells[gy] = [];
			for (var gx = 0; gx < gridWidth; gx++) {
				var sourceX = clamp(Math.floor((gx + 0.5) * pixels.width / gridWidth), 0, pixels.width - 1);
				var sourceY = clamp(Math.floor((gy + 0.5) * pixels.height / gridHeight), 0, pixels.height - 1);
				var index = (sourceY * pixels.width + sourceX) * 4;
				cells[gy][gx] = pixels.data[index + 3] >= 80 ? [pixels.data[index], pixels.data[index + 1], pixels.data[index + 2]] : null;
			}
		}
		var voxels = [];
		for (gy = 0; gy < gridHeight; gy++) {
			for (gx = 0; gx < gridWidth; gx++) {
				if (!cells[gy][gx]) {
					continue;
				}
				var interior = gx > 0 && gx < gridWidth - 1 && gy > 0 && gy < gridHeight - 1 && cells[gy][gx - 1] && cells[gy][gx + 1] && cells[gy - 1][gx] && cells[gy + 1][gx];
				var depthCells = interior ? 3 : 1;
				for (var layer = 0; layer < depthCells; layer++) {
					addVoxel(voxels, ((gx + 0.5) / gridWidth - 0.5) * 0.62, (layer - (depthCells - 1) * 0.5) * 0.065, (1 - (gy + 0.5) / gridHeight) * 0.80, cells[gy][gx], 0.032);
				}
			}
		}
		return voxels;
	}

	function buildNamedVoxelModel(profile, palette, pixels) {
		var voxels = [];
		if (profile === "container") {
			addShellBox(voxels, palette, 4, 3, 6, 0.62, 0.46, 0.82, 0.46, 0);
			addPlate(voxels, palette, 3, 1, 0.38, 0.05, 0.48, 2);
		} else if (profile === "machine") {
			addShellBox(voxels, palette, 4, 3, 5, 0.66, 0.50, 0.72, 0.40, 0);
			addPlate(voxels, palette, 3, 1, 0.40, 0.04, 0.55, 2);
		} else if (profile === "table") {
			addPlate(voxels, palette, 6, 4, 0.74, 0.52, 0.58, 0);
			addColumn(voxels, palette, -0.29, -0.19, 0.04, 0.54, 5, 1, 0.032);
			addColumn(voxels, palette, 0.29, -0.19, 0.04, 0.54, 5, 2, 0.032);
			addColumn(voxels, palette, -0.29, 0.19, 0.04, 0.54, 5, 3, 0.032);
			addColumn(voxels, palette, 0.29, 0.19, 0.04, 0.54, 5, 4, 0.032);
		} else if (profile === "chair") {
			addPlate(voxels, palette, 4, 4, 0.46, 0.46, 0.38, 0);
			addShellBox(voxels, palette, 4, 1, 4, 0.46, 0.07, 0.38, 0.63, 1);
			addColumn(voxels, palette, -0.17, -0.17, 0.04, 0.34, 3, 2, 0.025);
			addColumn(voxels, palette, 0.17, -0.17, 0.04, 0.34, 3, 3, 0.025);
			addColumn(voxels, palette, -0.17, 0.17, 0.04, 0.34, 3, 4, 0.025);
			addColumn(voxels, palette, 0.17, 0.17, 0.04, 0.34, 3, 0, 0.025);
		} else if (profile === "bed") {
			addPlate(voxels, palette, 7, 4, 0.82, 0.48, 0.27, 0);
			addShellBox(voxels, palette, 7, 1, 3, 0.82, 0.07, 0.30, 0.55, 2);
			addColumn(voxels, palette, -0.34, -0.18, 0.04, 0.22, 2, 3, 0.03);
			addColumn(voxels, palette, 0.34, 0.18, 0.04, 0.22, 2, 4, 0.03);
		} else if (profile === "pipe") {
			for (var pipeX = 0; pipeX < 9; pipeX++) {
				for (var pipeSide = 0; pipeSide < 4; pipeSide++) {
					var pipeAngle = pipeSide * Math.PI * 0.5;
					addVoxel(voxels, -0.36 + pipeX * 0.09, Math.cos(pipeAngle) * 0.07, 0.28 + Math.sin(pipeAngle) * 0.07, paletteColour(palette, pipeX + pipeSide), 0.035);
				}
			}
		} else if (profile === "plant") {
			addColumn(voxels, palette, 0, 0, 0.04, 0.52, 6, 1, 0.028);
			for (var plantX = -2; plantX <= 2; plantX++) {
				for (var plantY = -2; plantY <= 2; plantY++) {
					for (var plantZ = 0; plantZ < 4; plantZ++) {
						if (plantX * plantX + plantY * plantY + (plantZ - 1.5) * (plantZ - 1.5) <= 5.8) {
							addVoxel(voxels, plantX * 0.075, plantY * 0.075, 0.45 + plantZ * 0.09, paletteColour(palette, plantX + plantY + plantZ + 3), 0.037);
						}
					}
				}
			}
		} else if (profile === "lamp") {
			addPlate(voxels, palette, 3, 3, 0.24, 0.24, 0.05, 0);
			addColumn(voxels, palette, 0, 0, 0.08, 0.70, 7, 1, 0.025);
			addShellBox(voxels, palette, 3, 3, 2, 0.32, 0.32, 0.18, 0.78, 2);
		} else if (profile === "tool") {
			for (var toolPart = 0; toolPart < 9; toolPart++) {
				addVoxel(voxels, -0.34 + toolPart * 0.075, 0, 0.12 + toolPart * 0.045, paletteColour(palette, toolPart), 0.035);
			}
			addShellBox(voxels, palette, 3, 2, 2, 0.24, 0.16, 0.16, 0.58, 2);
		} else if (profile === "barrier" || profile === "door") {
			addShellBox(voxels, palette, 6, 1, 8, 0.74, 0.08, 0.94, 0.49, 0);
		} else if (profile === "flat_item") {
			addPlate(voxels, palette, 5, 4, 0.54, 0.40, 0.07, 0);
		} else if (profile === "stairs") {
			for (var step = 0; step < 5; step++) {
				for (var stepX = 0; stepX < 5; stepX++) {
					for (var stepZ = 0; stepZ <= step; stepZ++) {
						addVoxel(voxels, -0.30 + stepX * 0.15, -0.30 + step * 0.13, 0.06 + stepZ * 0.12, paletteColour(palette, step + stepX + stepZ), 0.052);
					}
				}
			}
		} else {
			return buildSculptedModel(pixels);
		}
		return voxels;
	}

	function buildVoxelModel(resource, entity) {
		var profile = semanticModel(entity);
		var cacheKey = resource + "|" + profile;
		if (voxelCache.hasOwnProperty(cacheKey) && voxelCache[cacheKey]) {
			return voxelCache[cacheKey];
		}
		var pixels = resourcePixels(resource);
		if (!pixels) {
			return null;
		}
		var voxels = buildNamedVoxelModel(profile, paletteFromPixels(pixels), pixels);
		voxelCache[cacheKey] = voxels;
		return voxels;
	}

	function shadedColour(colour, shade, light) {
		return "rgb(" + Math.floor(colour[0] * shade * light[0]) + "," + Math.floor(colour[1] * shade * light[1]) + "," + Math.floor(colour[2] * shade * light[2]) + ")";
	}

	function drawVoxelFace(points, colour) {
		var averageX = 0;
		var averageDepth = 0;
		for (var i = 0; i < points.length; i++) {
			if (!points[i]) {
				return;
			}
			averageX += points[i].x;
			averageDepth += points[i].depth;
		}
		averageX /= points.length;
		averageDepth /= points.length;
		if (averageDepth >= wallDepthAt(averageX)) {
			return;
		}
		context.beginPath();
		context.moveTo(points[0].x, points[0].y);
		for (var p = 1; p < points.length; p++) {
			context.lineTo(points[p].x, points[p].y);
		}
		context.closePath();
		context.fillStyle = colour;
		context.fill();
		context.strokeStyle = "rgba(0,0,0,0.24)";
		context.stroke();
	}

	function drawVoxel(entity, voxel, posX, posY, angle, focalLength, horizon, width, light) {
		var yaw = directionAngle(entity.dir || 2);
		var half = voxel.size || 0.034;
		var localY = voxel.y || 0;
		var centreX = voxel.x;
		var centreZ = voxel.z;
		var corners = [];
		for (var z = 0; z < 2; z++) {
			for (var y = 0; y < 2; y++) {
				for (var x = 0; x < 2; x++) {
					var localX = centreX + (x ? half : -half);
					var localDepth = localY + (y ? half : -half);
					var worldX = entity.x + localX * Math.cos(yaw) - localDepth * Math.sin(yaw);
					var worldY = entity.y + localX * Math.sin(yaw) + localDepth * Math.cos(yaw);
					corners.push(projectPoint(worldX, worldY, centreZ + (z ? half : -half), posX, posY, angle, focalLength, horizon, width));
				}
			}
		}

		var faces = [
			{ points: [corners[0], corners[1], corners[3], corners[2]], shade: 0.55 },
			{ points: [corners[4], corners[5], corners[7], corners[6]], shade: 1.18 },
			{ points: [corners[0], corners[1], corners[5], corners[4]], shade: 0.82 },
			{ points: [corners[1], corners[3], corners[7], corners[5]], shade: 0.96 },
			{ points: [corners[3], corners[2], corners[6], corners[7]], shade: 0.69 },
			{ points: [corners[2], corners[0], corners[4], corners[6]], shade: 0.77 }
		];
		faces.sort(function (left, right) {
			var leftDepth = 0;
			var rightDepth = 0;
			for (var i = 0; i < left.points.length; i++) {
				leftDepth += left.points[i] ? left.points[i].depth : 0;
				rightDepth += right.points[i] ? right.points[i].depth : 0;
			}
			return rightDepth - leftDepth;
		});
		for (var face = 0; face < faces.length; face++) {
			drawVoxelFace(faces[face].points, shadedColour(voxel.colour, faces[face].shade, light));
		}
	}

	function drawVoxelObject(entity, posX, posY, angle, width, height) {
		var voxels = buildVoxelModel(entity.sprite, entity);
		if (!voxels || !voxels.length) {
			return;
		}
		var focalLength = width / (2 * Math.tan(fov / 2));
		var horizon = height * 0.5;
		var centre = projectPoint(entity.x, entity.y, 0.4, posX, posY, angle, focalLength, horizon, width);
		if (!centre || centre.depth >= wallDepthAt(centre.x) - 0.04) {
			return;
		}
		var light = sceneLightingAt(Math.floor(entity.x), Math.floor(entity.y), centre.depth, 10);
		for (var i = 0; i < voxels.length; i++) {
			drawVoxel(entity, voxels[i], posX, posY, angle, focalLength, horizon, width, light);
		}
	}

	function drawEntities(posX, posY, angle, width, height) {
		if (!scene.entities) {
			return;
		}
		var renderables = [];
		for (var i = 0; i < scene.entities.length; i++) {
			var entity = scene.entities[i];
			if (!entity.sprite) {
				continue;
			}
			var dx = entity.x - posX;
			var dy = entity.y - posY;
			var depth = dx * Math.cos(angle) + dy * Math.sin(angle);
			if (depth > 0.1) {
				renderables.push({ entity: entity, depth: depth });
			}
		}
		renderables.sort(function (left, right) {
			return right.depth - left.depth;
		});
		for (var rendered = 0; rendered < renderables.length; rendered++) {
			var item = renderables[rendered].entity;
			if (item.kind === "mob") {
				drawBillboard(item, posX, posY, angle, width, height);
			} else {
				drawVoxelObject(item, posX, posY, angle, width, height);
			}
		}
	}

	function getPointerPosition(event) {
		var rect = canvas.getBoundingClientRect ? canvas.getBoundingClientRect() : null;
		var clientX = event.clientX !== undefined ? event.clientX : event.offsetX;
		var clientY = event.clientY !== undefined ? event.clientY : event.offsetY;
		var x = rect ? (clientX - rect.left) * canvas.width / rect.width : clientX;
		var y = rect ? (clientY - rect.top) * canvas.height / rect.height : clientY;
		return {
			x: Math.max(0, Math.min(canvas.width - 1, x)),
			y: Math.max(0, Math.min(canvas.height - 1, y))
		};
	}

	function getTargetedTile(event) {
		if (!scene || !scene.cells || !scene.cells.length) {
			return null;
		}
		var point = getPointerPosition(event);
		var radius = scene.radius;
		var posX = radius + 0.5;
		var posY = radius + 0.5;
		var angle = directionAngle(scene.dir);
		var rayAngle = angle - fov / 2 + (point.x / canvas.width) * fov;
		var rayX = Math.cos(rayAngle);
		var rayY = Math.sin(rayAngle);
		var hit = castRay(posX, posY, rayX, rayY);
		var closestEntity = null;
		var closestDistance = hit.distance;

		for (var i = 0; scene.entities && i < scene.entities.length; i++) {
			var entity = scene.entities[i];
			var dx = entity.x - posX;
			var dy = entity.y - posY;
			var forward = dx * rayX + dy * rayY;
			var lateral = Math.abs(-dx * rayY + dy * rayX);
			if (forward > 0.1 && forward < closestDistance && lateral < 0.36) {
				closestDistance = forward;
				closestEntity = entity;
			}
		}

		if (closestEntity) {
			return {
				x: Math.floor(closestEntity.x) - radius,
				y: radius - Math.floor(closestEntity.y)
			};
		}
		return {
			x: hit.mapX - radius,
			y: radius - hit.mapY
		};
	}

	function getClickAction(event) {
		if (event.button === 2) {
			return event.ctrlKey ? "alternate" : "context";
		}
		if (event.button === 1) {
			return "middle";
		}
		if (event.shiftKey) {
			return "examine";
		}
		if (event.ctrlKey) {
			return "pull";
		}
		return "primary";
	}

	function handleMouse(event) {
		var target = getTargetedTile(event);
		if (target) {
			byondCommand("Shock3DClick " + target.x + " " + target.y + " " + getClickAction(event));
		}
		if (event.preventDefault) {
			event.preventDefault();
		}
		return false;
	}

	function handleKey(event) {
		var key = event.keyCode;
		var command = null;
		var hasControl = !!event.ctrlKey;
		var hasShift = !!event.shiftKey;
		var hasAlt = !!event.altKey;
		var plain = !hasControl && !hasShift && !hasAlt;

		// Mirror interface/skin.dmf's standard "macro" bindings. The four bare
		// WASD keys are intentionally the sole exception: they operate the
		// first-person camera. Ctrl+W/A/S/D retain their normal DM commands.
		switch (key) {
		case 13:
			if (hasAlt && !hasControl && !hasShift) { command = "Toggle-Fullscreen"; }
			break;
		case 37:
			if (hasAlt && !hasControl && !hasShift) { command = "westfaceperm"; }
			else if (hasControl && !hasShift && !hasAlt) { command = "westface"; }
			else if (plain) { command = ".moveleft"; }
			break;
		case 38:
			if (hasAlt && !hasControl && !hasShift) { command = "northfaceperm"; }
			else if (hasControl && !hasShift && !hasAlt) { command = "northface"; }
			else if (plain) { command = ".moveup"; }
			break;
		case 39:
			if (hasAlt && !hasControl && !hasShift) { command = "eastfaceperm"; }
			else if (hasControl && !hasShift && !hasAlt) { command = "eastface"; }
			else if (plain) { command = ".moveright"; }
			break;
		case 40:
			if (hasAlt && !hasControl && !hasShift) { command = "southfaceperm"; }
			else if (hasControl && !hasShift && !hasAlt) { command = "southface"; }
			else if (plain) { command = ".movedown"; }
			break;
		case 45: if (plain) { command = "a-intent right"; } break; // Insert
		case 46: if (plain) { command = "delete-key-pressed"; } break; // Delete
		case 49: if (plain || (hasControl && !hasShift && !hasAlt)) { command = "a-intent help"; } break;
		case 50: if (plain || (hasControl && !hasShift && !hasAlt)) { command = "a-intent disarm"; } break;
		case 51: if (plain || (hasControl && !hasShift && !hasAlt)) { command = "a-intent grab"; } break;
		case 52: if (plain || (hasControl && !hasShift && !hasAlt)) { command = "a-intent harm"; } break;
		case 53: if (plain) { command = ".me"; } break;
		case 65: if (hasControl && !hasShift && !hasAlt) { command = ".moveleft"; } else if (plain) { command = "Shock3DTurn left"; } break; // A
		case 67: if (plain) { command = ".combat_mode"; } break;
		case 68: if (hasControl && !hasShift && !hasAlt) { command = ".moveright"; } else if (plain) { command = "Shock3DTurn right"; } break; // D
		case 69: if (plain || (hasControl && !hasShift && !hasAlt)) { command = "quick-equip"; } break;
		case 70: if (hasControl && !hasShift && !hasAlt) { command = "a-intent left"; } else if (plain) { command = ".fixeye"; } break;
		case 71: if (hasControl && !hasShift && !hasAlt) { command = "a-intent right"; } else if (plain) { command = ".defense_intent"; } break;
		case 72: if (plain || (hasControl && !hasShift && !hasAlt)) { command = "holster"; } break;
		case 79: if (plain) { command = "ooc"; } break;
		case 81: if (plain || (hasControl && !hasShift && !hasAlt)) { command = ".northwest"; } break;
		case 82: if (plain || (hasControl && !hasShift && !hasAlt)) { command = ".southwest"; } break;
		case 83: if (hasControl && !hasShift && !hasAlt) { command = ".movedown"; } else if (plain) { command = "Shock3DMove backward"; } break; // S
		case 84: if (plain) { command = ".say"; } break;
		case 86: if (plain) { command = ".mob_rest"; } break;
		case 87: if (hasControl && !hasShift && !hasAlt) { command = ".moveup"; } else if (plain) { command = "Shock3DMove forward"; } break; // W
		case 88: if (hasControl && !hasShift && !hasAlt) { command = ".northeast"; } else if (hasShift && !hasAlt && !hasControl) { command = ".wield"; } else if (plain) { command = ".northeast"; } break;
		case 89: case 90: if (plain || (hasControl && !hasShift && !hasAlt)) { command = "Activate-Held-Object"; } break;
		case 97: if (plain) { command = "body-r-leg"; } break; // Numpad1
		case 98: if (plain) { command = "body-groin"; } break;
		case 99: if (plain) { command = "body-l-leg"; } break;
		case 100: if (plain) { command = "body-r-arm"; } break;
		case 101: if (plain) { command = "body-chest"; } break;
		case 102: if (plain) { command = "body-l-arm"; } break;
		case 104: if (plain) { command = "body-toggle-head"; } break;
		case 112: if (hasControl && hasShift && !hasAlt) { command = ".options"; } else if (plain) { command = "adminhelp"; } break;
		case 113:
			if (hasShift && !hasControl && !hasAlt) {
				if (!event.repeat) { command = ".screenshot"; }
			} else if (plain) {
				command = event.repeat ? ".screenshot auto" : "ooc";
			}
			break;
		case 114: if (plain) { command = ".say"; } break;
		case 115: if (plain) { command = ".me"; } break;
		case 116: if (plain) { command = "asay"; } break;
		case 117: if (plain) { command = "Player-Panel-New"; } break;
		case 118: if (plain) { command = "Admin-PM"; } break;
		case 119: if (plain) { command = "Invisimin"; } break;
		case 120: if (plain) { command = "ReloadPig"; } break;
		case 188: if (plain) { command = "move-upwards"; } break;
		case 190: if (plain) { command = "move-down"; } break;
		}
		if (!command) {
			return;
		}
		byondCommand(command);
		if (event.preventDefault) {
			event.preventDefault();
		}
		return false;
	}

	function draw() {
		if (!context) {
			return;
		}
		resize();
		var width = canvas.width;
		var height = canvas.height;
		context.imageSmoothingEnabled = false;
		context.webkitImageSmoothingEnabled = false;
		context.clearRect(0, 0, width, height);
		if (!scene || !scene.cells || !scene.cells.length) {
			status.innerHTML = "SYSTEM SHOCK 3D // WAITING FOR VISUAL DATA";
			return;
		}

		var radius = scene.radius;
		var posX = radius + 0.5;
		var posY = radius + 0.5;
		var angle = directionAngle(scene.dir);
		drawBackdrop(width, height);
		drawTexturedFloors(posX, posY, angle, width, height);
		drawWalls(posX, posY, angle, width, height);
		drawEntities(posX, posY, angle, width, height);
		status.innerHTML = "SYSTEM SHOCK 3D // NATIVE LIGHTING, TEXTURE, VOXEL, AND SPRITE LINK ACTIVE";
	}

	window.setScene = function (payload) {
		try {
			scene = typeof payload === "string" ? JSON.parse(payload) : payload;
			draw();
		} catch (error) {
			status.innerHTML = "SYSTEM SHOCK 3D // DATA LINK ERROR";
		}
	};

	window.onresize = draw;
	canvas.addEventListener("mousedown", handleMouse, false);
	canvas.addEventListener("contextmenu", function (event) {
		if (event.preventDefault) {
			event.preventDefault();
		}
		return false;
	}, false);
	document.addEventListener("keydown", handleKey, false);
	resize();
	draw();
	if (canvas.focus) {
		canvas.focus();
	}
	window.location = "byond://winset?command=Shock3DReady";
}());
