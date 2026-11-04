// PICO-8 glue for the T-box game console / CRT television window.
//
// The server opens this window in one of two roles (window.TBOX_CFG.role):
//  - "player": runs the PICO8 runtime locally (optionally resuming from a
//    server-held savestate), owns input, and continuously uploads both a
//    low-rate full savestate (persistence) and a higher-rate framebuffer
//    delta stream (live spectating) through chunked byond:// hrefs.
//  - "spectator": runs no emulator at all; it just blits framebuffer
//    keyframes/deltas pushed from the server, mirroring the player exactly.
//
// Server -> client calls (via output()): tboxFrame, tboxKeyframe, tboxReset,
// tboxEject, tboxPause, tboxKick.
(function () {
	'use strict';

	var cfg = window.TBOX_CFG || {};
	var canvas = null;
	var overlay = null;

	var W = 128;
	var H = 128;
	var SIZE = W * H;

	// Spectator-side framebuffer mirror.
	var sfb = null;
	var sfbSeq = -1;

	// Player-side last streamed frame.
	var lastSent = null;
	var lastSentSeq = -1;

	var KEYMAP = {
		37: 0, // ArrowLeft
		39: 1, // ArrowRight
		38: 2, // ArrowUp
		40: 3, // ArrowDown
		90: 4, // Z -> O
		88: 5, // X -> X
		65: 6, // A -> player2 left
		83: 7, // S -> player2 right
		13: 8, // Enter
		80: 9  // P
	};

	// ---- server messaging ------------------------------------------------------
	// Rapid window.location changes can swallow each other, so hrefs go through
	// a paced queue.
	var sendQueue = [];
	var uploadSeq = 0;

	setInterval(function () {
		if (sendQueue.length) {
			window.location.href = sendQueue.shift();
		}
	}, 60);

	function queueHref(params) {
		var parts = [];
		for (var k in params) {
			if (Object.prototype.hasOwnProperty.call(params, k)) {
				parts.push(k + '=' + params[k]);
			}
		}
		sendQueue.push('byond://?src=' + cfg.src + ';' + parts.join(';'));
	}

	// Uploads arbitrary text to the server split into URL-safe chunks that stay
	// under the embedded browser's URL length limit.
	function sendChunked(kind, text) {
		var seq = ++uploadSeq;
		var enc = encodeURIComponent(text);
		var chunks = [];
		var pos = 0;
		while (pos < enc.length) {
			var end = Math.min(pos + 1200, enc.length);
			// Never split a %XX escape sequence across chunks.
			while (end < enc.length && end > pos + 2 && (enc.charAt(end - 1) === '%' || enc.charAt(end - 2) === '%')) {
				end--;
			}
			chunks.push(enc.substring(pos, end));
			pos = end;
		}
		for (var i = 0; i < chunks.length; i++) {
			queueHref({ tbup: 1, k: kind, q: seq, i: i + 1, n: chunks.length, d: chunks[i] });
		}
	}

	// ---- helpers ---------------------------------------------------------------
	function setOverlay(text) {
		if (!overlay) { return; }
		if (text) {
			overlay.innerHTML = text;
			overlay.style.display = 'block';
		} else {
			overlay.style.display = 'none';
		}
	}

	function copyFb(src) {
		var out = new Uint8Array(SIZE);
		for (var i = 0; i < SIZE; i++) { out[i] = src[i] & 15; }
		return out;
	}

	// Delta format: dot-separated segments of 'start(base36):hexpixels'.
	function makeDelta(prev, cur) {
		var segs = [];
		var i = 0;
		while (i < SIZE) {
			if (prev[i] === (cur[i] & 15)) { i++; continue; }
			var start = i;
			var j = i;
			var gap = 0;
			// Merge changes separated by small gaps into one segment.
			while (j < SIZE && gap <= 4) {
				if (prev[j] !== (cur[j] & 15)) { gap = 0; } else { gap++; }
				j++;
			}
			var end = j - gap;
			var hex = '';
			for (var k = start; k < end; k++) { hex += (cur[k] & 15).toString(16); }
			segs.push(start.toString(36) + ':' + hex);
			i = j;
		}
		return segs.join('.');
	}

	function applyDelta(fb, delta) {
		if (!delta) { return; }
		var segs = delta.split('.');
		for (var s = 0; s < segs.length; s++) {
			var colon = segs[s].indexOf(':');
			if (colon < 1) { continue; }
			var start = parseInt(segs[s].substring(0, colon), 36);
			var hex = segs[s].substring(colon + 1);
			for (var k = 0; k < hex.length && start + k < SIZE; k++) {
				var c = parseInt(hex.charAt(k), 16);
				if (!isNaN(c)) { fb[start + k] = c; }
			}
		}
	}

	// ---- player role -----------------------------------------------------------
	var frameTimer = null;
	var stateTimer = null;
	var halted = false;
	var inputEnabled = false;
	var inputAttached = false;

	function pressButton(btn, down) {
		if (inputEnabled && window.PICO8) {
			window.PICO8.setButton(btn, down);
		}
	}

	function clearButtons() {
		if (window.PICO8) {
			for (var i = 0; i < 10; i++) { window.PICO8.setButton(i, false); }
		}
	}

	function refocusCanvas() {
		if (canvas && canvas.focus) {
			try { canvas.focus(); } catch (e) { /* ignore */ }
		}
	}

	function attachInput() {
		inputEnabled = true;
		if (inputAttached) {
			refocusCanvas();
			return;
		}
		inputAttached = true;

		var onDown = function (e) {
			e = e || window.event;
			var btn = KEYMAP[e.keyCode || e.which];
			if (btn !== undefined && inputEnabled) {
				pressButton(btn, true);
				if (e.preventDefault) { e.preventDefault(); }
				return false;
			}
		};
		var onUp = function (e) {
			e = e || window.event;
			var btn = KEYMAP[e.keyCode || e.which];
			if (btn !== undefined && inputEnabled) {
				pressButton(btn, false);
				if (e.preventDefault) { e.preventDefault(); }
				return false;
			}
		};

		// Belt and braces: the BYOND browser control is finicky about which
		// target ends up with keyboard focus, so listen everywhere (capture
		// phase) and keep pulling focus back to the canvas.
		if (document.addEventListener) {
			document.addEventListener('keydown', onDown, true);
			document.addEventListener('keyup', onUp, true);
			window.addEventListener('keydown', onDown, true);
			window.addEventListener('keyup', onUp, true);
			window.addEventListener('blur', clearButtons, false);
			document.addEventListener('mousedown', function () { setTimeout(refocusCanvas, 0); }, true);
		} else {
			document.onkeydown = onDown;
			document.onkeyup = onUp;
		}

		canvas.tabIndex = 0;
		canvas.style.outline = 'none';
		refocusCanvas();
		setTimeout(refocusCanvas, 200);

		// On-screen control pad: mouse input works even when key events never
		// reach the page.
		if (document.querySelectorAll) {
			var pads = document.querySelectorAll('[data-btn]');
			var bindPad = function (el) {
				var btn = parseInt(el.getAttribute('data-btn'), 10);
				el.onmousedown = function (e) {
					pressButton(btn, true);
					if (e && e.preventDefault) { e.preventDefault(); }
					return false;
				};
				el.onmouseup = function () { pressButton(btn, false); };
				el.onmouseleave = function () { pressButton(btn, false); };
				el.onselectstart = function () { return false; };
			};
			for (var p = 0; p < pads.length; p++) { bindPad(pads[p]); }
			document.addEventListener('mouseup', clearButtons, false);
		}
	}

	function sendFrame() {
		if (halted || !window.PICO8 || !window.PICO8.isRunning()) { return; }
		var scr = window.PICO8.getScreen();
		if (lastSent && scr.seq === lastSentSeq) { return; }
		if (!lastSent) {
			sendChunked('fr', 'K|' + scr.seq + '|' + window.PICO8.rleEncode(scr.fb));
			lastSent = copyFb(scr.fb);
			lastSentSeq = scr.seq;
			return;
		}
		var delta = makeDelta(lastSent, scr.fb);
		if (delta.length > 1600) {
			sendChunked('fr', 'K|' + scr.seq + '|' + window.PICO8.rleEncode(scr.fb));
		} else {
			sendChunked('fr', 'D|' + lastSentSeq + '|' + scr.seq + '|' + delta);
		}
		lastSent = copyFb(scr.fb);
		lastSentSeq = scr.seq;
	}

	function sendSnapshot() {
		if (halted || !window.PICO8 || !window.PICO8.isRunning()) { return; }
		var st = window.PICO8.saveState();
		if (st) {
			sendChunked('ss', JSON.stringify(st));
		}
	}

	function haltPlayer(message) {
		halted = true;
		inputEnabled = false;
		clearButtons();
		if (frameTimer) { clearInterval(frameTimer); frameTimer = null; }
		if (stateTimer) { clearInterval(stateTimer); stateTimer = null; }
		if (window.PICO8) { window.PICO8.destroy(); }
		if (message) { setOverlay(message); }
	}

	function bootPlayer(state) {
		if (!window.PICO8) {
			setOverlay('EMULATOR MISSING');
			return;
		}
		halted = false;
		setOverlay(null);
		lastSent = null;
		lastSentSeq = -1;
		window.PICO8.onError = function (msg) {
			setOverlay('CART ERROR<br>' + msg);
		};
		window.PICO8.load(cfg.cart, canvas, state || null);
		attachInput();
		if (!frameTimer) { frameTimer = setInterval(sendFrame, 250); }
		if (!stateTimer) { stateTimer = setInterval(sendSnapshot, 1600); }
	}

	// ---- spectator role ----------------------------------------------------------
	function redrawSpectator() {
		if (window.PICO8 && sfb) {
			window.PICO8.drawTo(canvas, sfb);
		}
	}

	function bootSpectator() {
		sfb = new Uint8Array(SIZE);
		sfbSeq = -1;
		if (cfg.fb && window.PICO8) {
			window.PICO8.rleDecode(cfg.fb, sfb);
			sfbSeq = (cfg.fbSeq | 0) || 0;
		}
		redrawSpectator();
		if (sfbSeq < 0) { setOverlay('TUNING IN...'); }
	}

	// ---- server push entry points ------------------------------------------------
	window.tboxFrame = function (payload) {
		if (cfg.role !== 'spectator' || !sfb) { return; }
		var txt = String(payload);
		var p1 = txt.indexOf('|');
		if (p1 < 0) { return; }
		var type = txt.substring(0, p1);
		if (type === 'K') {
			var p2 = txt.indexOf('|', p1 + 1);
			if (p2 < 0) { return; }
			sfb.fill(0);
			window.PICO8.rleDecode(txt.substring(p2 + 1), sfb);
			sfbSeq = parseInt(txt.substring(p1 + 1, p2), 10);
			setOverlay(null);
			redrawSpectator();
		} else if (type === 'D') {
			var parts = txt.split('|');
			if (parts.length < 4) { return; }
			var base = parseInt(parts[1], 10);
			if (base !== sfbSeq) { return; } // wait for the next keyframe
			applyDelta(sfb, parts[3]);
			sfbSeq = parseInt(parts[2], 10);
			setOverlay(null);
			redrawSpectator();
		}
	};

	// Key event forwarded by the server from the BYOND "tbox" macro set.
	window.tboxKey = function (btn, down) {
		if (cfg.role !== 'player') { return; }
		var b = parseInt(btn, 10);
		if (isNaN(b)) { return; }
		pressButton(b, down === '1' || down === 1);
	};

	// Server asks the player to emit a fresh keyframe (a spectator joined).
	window.tboxKeyframe = function () {
		if (cfg.role === 'player') {
			lastSent = null;
			lastSentSeq = -1;
		}
	};

	// Console reset: reboot the cart from scratch.
	window.tboxReset = function () {
		if (cfg.role === 'player') {
			cfg.state = null;
			bootPlayer(null);
		} else {
			if (sfb) { sfb.fill(0); }
			sfbSeq = -1;
			redrawSpectator();
			setOverlay('REBOOTING...');
		}
	};

	// Cartridge pulled from the console.
	window.tboxEject = function () {
		if (cfg.role === 'player') {
			haltPlayer('NO CARTRIDGE');
		} else {
			if (sfb) { sfb.fill(0); }
			sfbSeq = -1;
			redrawSpectator();
			setOverlay('NO CARTRIDGE');
		}
	};

	// The player stopped playing; the game is frozen server-side.
	window.tboxPause = function () {
		if (cfg.role === 'spectator') {
			setOverlay('STANDBY');
		}
	};

	// This viewer's session was ended by the server.
	window.tboxKick = function (message) {
		if (cfg.role === 'player') {
			haltPlayer(message || 'SIGNAL LOST');
		} else {
			setOverlay(message || 'SIGNAL LOST');
		}
	};

	// ---- boot ----------------------------------------------------------------
	function boot() {
		canvas = document.getElementById('p8screen');
		overlay = document.getElementById('p8overlay');
		if (!canvas) { return; }
		if (cfg.role === 'player') {
			bootPlayer(cfg.state || null);
		} else {
			bootSpectator();
		}
	}

	if (document.readyState === 'complete' || document.readyState === 'interactive') {
		boot();
	} else if (window.addEventListener) {
		window.addEventListener('load', boot, false);
	} else {
		window.onload = boot;
	}
}());
