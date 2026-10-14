/*
 * pico8.js - PICO-8-inspired fantasy console runtime for the in-game PDA.
 *
 * Runs plain-text .p8 cartridges (the __lua__ section) on a Fengari Lua 5.3 VM
 * and renders the 128x128 display onto a canvas with a PICO-8 style API subset:
 * cls, pset, pget, spr, sspr, rect, rectfill, circ, circfill, line, print,
 * btn, btnp, rnd, srand, flr, ceil, abs, min, max, mid, sin, cos, atan2, sqrt,
 * sgn, time, stat, gpio, camera, mget, mset, sprset.
 *
 * The Lua VM wrapper and transpiler approach are adapted from the MIT licensed
 * "pico8-web-emulator" by Brooklyn Baylis (https://github.com/Brooklyn-Dev/pico8-web-emulator).
 * The VM itself is Fengari (MIT license, https://fengari.io) shipped separately
 * as pico8_fengari.js.
 *
 * This project (Interpost-Hague) is licensed under the AGPL; this file is MIT.
 */
(function (global) {
	'use strict';

	var FW = global.pico8_fengari;
	if (!FW) {
		global.pico8_missing = true;
		return;
	}

	var lua = FW.lua;
	var lauxlib = FW.lauxlib;
	var lualib = FW.lualib;
	var to_luastring = FW.to_luastring;
	var to_jsstring = FW.to_jsstring;

	var LUA_OK = 0;
	var WIDTH = 128;
	var HEIGHT = 128;
	var FRAME_MS = 1000 / 30;

	var PALETTE = [
		'#000000', '#1D2B53', '#7E2553', '#008751', '#AB5236', '#5F574F',
		'#C2C3C7', '#FFF1E8', '#FF004D', '#FFA300', '#FFEC27', '#00E436',
		'#29ADFF', '#83769C', '#FF77A8', '#FFCCAA'
	].map(function (hex) {
		var v = parseInt(hex.substring(1), 16);
		return [(v >> 16) & 255, (v >> 8) & 255, v & 255];
	});

	// Compact 3x5 pixel font (advance 4px), uppercase only.
	var FONT = {
		'A': ['010', '101', '111', '101', '101'],
		'B': ['110', '101', '110', '101', '110'],
		'C': ['011', '100', '100', '100', '011'],
		'D': ['110', '101', '101', '101', '110'],
		'E': ['111', '100', '110', '100', '111'],
		'F': ['111', '100', '110', '100', '100'],
		'G': ['011', '100', '101', '101', '011'],
		'H': ['101', '101', '111', '101', '101'],
		'I': ['111', '010', '010', '010', '111'],
		'J': ['001', '001', '001', '101', '010'],
		'K': ['101', '101', '110', '101', '101'],
		'L': ['100', '100', '100', '100', '111'],
		'M': ['101', '111', '101', '101', '101'],
		'N': ['101', '111', '111', '101', '101'],
		'O': ['010', '101', '101', '101', '010'],
		'P': ['110', '101', '110', '100', '100'],
		'Q': ['010', '101', '101', '110', '001'],
		'R': ['110', '101', '110', '101', '101'],
		'S': ['011', '100', '010', '001', '110'],
		'T': ['111', '010', '010', '010', '010'],
		'U': ['101', '101', '101', '101', '010'],
		'V': ['101', '101', '101', '101', '010'],
		'W': ['101', '101', '111', '101', '101'],
		'X': ['101', '101', '010', '101', '101'],
		'Y': ['101', '101', '010', '010', '010'],
		'Z': ['111', '001', '010', '100', '111'],
		'0': ['010', '101', '101', '101', '010'],
		'1': ['010', '110', '010', '010', '111'],
		'2': ['110', '001', '010', '100', '111'],
		'3': ['110', '001', '010', '001', '110'],
		'4': ['101', '101', '011', '001', '001'],
		'5': ['111', '100', '110', '001', '110'],
		'6': ['011', '100', '110', '101', '010'],
		'7': ['111', '001', '010', '010', '010'],
		'8': ['010', '101', '010', '101', '010'],
		'9': ['010', '101', '011', '001', '110'],
		'!': ['010', '010', '010', '000', '010'],
		'?': ['110', '001', '010', '000', '010'],
		'.': ['000', '000', '000', '000', '010'],
		',': ['000', '000', '000', '010', '100'],
		'-': ['000', '000', '111', '000', '000'],
		':': ['000', '010', '000', '010', '000'],
		"'": ['010', '010', '000', '000', '000'],
		'(': ['001', '010', '010', '010', '001'],
		')': ['100', '010', '010', '010', '100'],
		'<': ['001', '010', '100', '010', '001'],
		'>': ['100', '010', '001', '010', '100'],
		'*': ['000', '101', '010', '101', '000'],
		'+': ['000', '010', '111', '010', '000'],
		'/': ['001', '001', '010', '100', '100'],
		' ': ['000', '000', '000', '000', '000']
	};

	// ---- runtime state -------------------------------------------------------
	var canvasEl = null;
	var ctx = null;
	var imgData = null;

	var gfx = new Uint8Array(WIDTH * HEIGHT);      // sprite sheet
	var mapMem = new Uint8Array(WIDTH * 64);       // map memory
	var fb = new Uint8Array(WIDTH * HEIGHT);       // framebuffer

	var camX = 0;
	var camY = 0;

	var keyState = new Array(8).fill(false);
	var prevKey = new Array(8).fill(false);
	var gpioMem = new Int32Array(128);

	var rng = 0x524F43;
	var vm = null;
	var rafId = null;
	var startTime = 0;
	var lastTs = 0;
	var acc = 0;
	var running = false;

	var lastError = '';
	var onGpio = null;
	var onError = null;

	var PALETTE_RGB = [];
	PALETTE.forEach(function (rgb) {
		PALETTE_RGB.push(rgb[0], rgb[1], rgb[2], 255);
	});

	// ---- small helpers -------------------------------------------------------
	function getN(L, idx, def) {
		if (lua.lua_isnoneornil(L, idx)) { return def; }
		return lua.lua_tonumber(L, idx);
	}

	function getB(L, idx) {
		if (lua.lua_isnoneornil(L, idx)) { return false; }
		return lua.lua_toboolean(L, idx);
	}

	function getS(L, idx, def) {
		if (lua.lua_isnoneornil(L, idx)) { return def; }
		var s = lua.lua_tolstring(L, idx);
		return s ? to_jsstring(s) : def;
	}

	function isNumArg(L, idx) {
		return !lua.lua_isnoneornil(L, idx) && lua.lua_isnumber(L, idx);
	}

	function pushNum(L, v) {
		lua.lua_pushnumber(L, v);
		return 1;
	}

	function putPix(x, y, c) {
		x = (x - camX) | 0;
		y = (y - camY) | 0;
		if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT) { return; }
		fb[y * WIDTH + x] = c & 15;
	}

	function getPix(x, y) {
		x = (x - camX) | 0;
		y = (y - camY) | 0;
		if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT) { return 0; }
		return fb[y * WIDTH + x];
	}

	function nextRand() {
		rng = (rng * 1103515245 + 12345) & 0x7fffffff;
		return rng / 0x7fffffff;
	}

	function drawText(text, x, y, col) {
		col = col & 15;
		var cx = x | 0;
		var cy = y | 0;
		var upper = text.toUpperCase();
		for (var i = 0; i < upper.length; i++) {
			var glyph = FONT[upper.charAt(i)];
			if (!glyph) { glyph = FONT['?']; }
			for (var row = 0; row < 5; row++) {
				var bits = glyph[row];
				for (var colIdx = 0; colIdx < 3; colIdx++) {
					if (bits.charAt(colIdx) === '1') {
						putPix(cx + colIdx, cy + row, col);
					}
				}
			}
			cx += 4;
		}
	}

	// ---- PICO-8 API ----------------------------------------------------------
	function api_cls(L) {
		var col = getN(L, 1, 0) & 15;
		fb.fill(col);
		return 0;
	}

	function api_pset(L) {
		var x = getN(L, 1, 0);
		var y = getN(L, 2, 0);
		var c = getN(L, 3, 0);
		putPix(x, y, c);
		return 0;
	}

	function api_pget(L) {
		var x = getN(L, 1, 0);
		var y = getN(L, 2, 0);
		return pushNum(L, getPix(x, y));
	}

	function api_camera(L) {
		var nx = getN(L, 1, 0);
		var ny = getN(L, 2, 0);
		var px = camX;
		var py = camY;
		camX = nx | 0;
		camY = ny | 0;
		lua.lua_pushnumber(L, px);
		lua.lua_pushnumber(L, py);
		return 2;
	}

	function api_spr(L) {
		var n = getN(L, 1, 0) | 0;
		var x = getN(L, 2, 0) | 0;
		var y = getN(L, 3, 0) | 0;
		var w = getN(L, 4, 1) | 0;
		var h = getN(L, 5, 1) | 0;
		var flipX = getB(L, 6);
		var flipY = getB(L, 7);
		if (w < 1) { w = 1; }
		if (h < 1) { h = 1; }
		var sx = (n % 16) * 8;
		var sy = Math.floor(n / 16) * 8;
		var dx, dy, px, py, si;
		for (dy = 0; dy < h * 8; dy++) {
			py = flipY ? (h * 8 - 1 - dy) : dy;
			for (dx = 0; dx < w * 8; dx++) {
				px = flipX ? (w * 8 - 1 - dx) : dx;
				si = (sy + py) * WIDTH + sx + px;
				putPix(x + dx, y + dy, gfx[si]);
			}
		}
		return 0;
	}

	function api_sspr(L) {
		var sx = getN(L, 1, 0) | 0;
		var sy = getN(L, 2, 0) | 0;
		var sw = getN(L, 3, 8) | 0;
		var sh = getN(L, 4, 8) | 0;
		var dx0 = getN(L, 5, 0) | 0;
		var dy0 = getN(L, 6, 0) | 0;
		var dw = getN(L, 7, sw) | 0;
		var dh = getN(L, 8, sh) | 0;
		var flipX = getB(L, 9);
		var flipY = getB(L, 10);
		if (dw < 1) { dw = 1; }
		if (dh < 1) { dh = 1; }
		if (sw < 1) { sw = 1; }
		if (sh < 1) { sh = 1; }
		var dy, dx2, t;
		for (dy = 0; dy < dh; dy++) {
			t = ((sy + (dy * sh) / dh) | 0) * WIDTH;
			for (dx2 = 0; dx2 < dw; dx2++) {
				var src = gfx[t + ((sx + (dx2 * sw) / dw) | 0)];
				putPix(dx0 + (flipX ? dw - 1 - dx2 : dx2), dy0 + (flipY ? dh - 1 - dy : dy), src);
			}
		}
		return 0;
	}

	function api_rect(L) {
		var x0 = getN(L, 1, 0) | 0;
		var y0 = getN(L, 2, 0) | 0;
		var x1 = getN(L, 3, 0) | 0;
		var y1 = getN(L, 4, 0) | 0;
		var col = getN(L, 5, 0);
		var x, y;
		for (x = x0; x <= x1; x++) { putPix(x, y0, col); putPix(x, y1, col); }
		for (y = y0; y <= y1; y++) { putPix(x0, y, col); putPix(x1, y, col); }
		return 0;
	}

	function api_rectfill(L) {
		var x0 = getN(L, 1, 0) | 0;
		var y0 = getN(L, 2, 0) | 0;
		var x1 = getN(L, 3, 0) | 0;
		var y1 = getN(L, 4, 0) | 0;
		var col = getN(L, 5, 0);
		var x, y;
		for (y = y0; y <= y1; y++) {
			for (x = x0; x <= x1; x++) { putPix(x, y, col); }
		}
		return 0;
	}

	function api_circ(L) {
		var cx = getN(L, 1, 0);
		var cy = getN(L, 2, 0);
		var r = getN(L, 3, 0);
		var col = getN(L, 4, 0);
		var x, y, d;
		var rOuter = r + 0.5;
		var rInner = r - 0.5;
		for (y = cy - r - 1; y <= cy + r + 1; y++) {
			for (x = cx - r - 1; x <= cx + r + 1; x++) {
				d = Math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
				if (d >= rInner && d <= rOuter) { putPix(x, y, col); }
			}
		}
		return 0;
	}

	function api_circfill(L) {
		var cx = getN(L, 1, 0);
		var cy = getN(L, 2, 0);
		var r = getN(L, 3, 0);
		var col = getN(L, 4, 0);
		var x, y;
		var r2 = r * r;
		for (y = cy - r - 1; y <= cy + r + 1; y++) {
			for (x = cx - r - 1; x <= cx + r + 1; x++) {
				if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2 + r) { putPix(x, y, col); }
			}
		}
		return 0;
	}

	function api_line(L) {
		var x0 = getN(L, 1, 0) | 0;
		var y0 = getN(L, 2, 0) | 0;
		var x1 = getN(L, 3, 0) | 0;
		var y1 = getN(L, 4, 0) | 0;
		var col = getN(L, 5, 0);
		var dx = Math.abs(x1 - x0);
		var sx = x0 < x1 ? 1 : -1;
		var dy = -Math.abs(y1 - y0);
		var sy = y0 < y1 ? 1 : -1;
		var err = dx + dy;
		for (;;) {
			putPix(x0, y0, col);
			if (x0 === x1 && y0 === y1) { break; }
			var e2 = 2 * err;
			if (e2 >= dy) { err += dy; x0 += sx; }
			if (e2 <= dx) { err += dx; y0 += sy; }
		}
		return 0;
	}

	function api_print(L) {
		var top = lua.lua_gettop(L);
		var x = 0, y = 0, col = 7, contentEnd = top;
		if (top >= 3 && isNumArg(L, top) && isNumArg(L, top - 1) && isNumArg(L, top - 2)) {
			col = getN(L, top, 7);
			y = getN(L, top - 1, 0);
			x = getN(L, top - 2, 0);
			contentEnd = top - 3;
		} else if (top >= 2 && isNumArg(L, top) && isNumArg(L, top - 1)) {
			y = getN(L, top, 0);
			x = getN(L, top - 1, 0);
			contentEnd = top - 2;
		} else if (top >= 1 && isNumArg(L, top) && contentEnd > top - 3) {
			x = getN(L, top, 0);
			contentEnd = top - 1;
		}
		var out = '';
		for (var i = 1; i <= contentEnd; i++) {
			if (!lua.lua_isnoneornil(L, i)) {
				lauxlib.luaL_tolstring(L, i);
				var s = lua.lua_tolstring(L, -1);
				if (s) { out += to_jsstring(s); }
				lua.lua_pop(L, 1);
			}
		}
		drawText(out, x, y, col);
		return 0;
	}

	function api_btn(L) {
		var i = getN(L, 1, 0);
		lua.lua_pushboolean(L, !!keyState[i]);
		return 1;
	}

	function api_btnp(L) {
		var i = getN(L, 1, 0);
		lua.lua_pushboolean(L, !!keyState[i] && !prevKey[i]);
		return 1;
	}

	function api_rnd(L) {
		var x = getN(L, 1, 0);
		if (lua.lua_isnoneornil(L, 1) || x <= 1) {
			return pushNum(L, nextRand());
		}
		return pushNum(L, Math.floor(nextRand() * x));
	}

	function api_srand(L) {
		var x = getN(L, 1, 0);
		rng = (x | 0) || 1;
		return 0;
	}

	function api_flr(L) { return pushNum(L, Math.floor(getN(L, 1, 0))); }
	function api_ceil(L) { return pushNum(L, Math.ceil(getN(L, 1, 0))); }
	function api_abs(L) { return pushNum(L, Math.abs(getN(L, 1, 0))); }
	function api_sqrt(L) { return pushNum(L, Math.sqrt(getN(L, 1, 0))); }
	function api_sin(L) { return pushNum(L, Math.sin(getN(L, 1, 0))); }
	function api_cos(L) { return pushNum(L, Math.cos(getN(L, 1, 0))); }

	function api_atan2(L) {
		var dx = getN(L, 1, 0);
		var dy = getN(L, 2, 0);
		return pushNum(L, Math.atan2(dy, dx));
	}

	function api_sgn(L) {
		var x = getN(L, 1, 0);
		return pushNum(L, x > 0 ? 1 : (x < 0 ? -1 : 0));
	}

	function api_min(L) {
		var a = getN(L, 1, 0);
		var b = getN(L, 2, 0);
		return pushNum(L, a < b ? a : b);
	}

	function api_max(L) {
		var a = getN(L, 1, 0);
		var b = getN(L, 2, 0);
		return pushNum(L, a > b ? a : b);
	}

	function api_mid(L) {
		var a = getN(L, 1, 0);
		var b = getN(L, 2, 0);
		var c = getN(L, 3, 0);
		if (a < b) { a = b; }
		if (a > c) { a = c; }
		return pushNum(L, a);
	}

	function api_time(L) {
		return pushNum(L, (performance.now() - startTime) / 1000);
	}

	function api_stat(L) {
		lua.lua_pushnumber(L, 0);
		return 1;
	}

	function api_gpio(L) {
		var i = getN(L, 1, 0);
		if (!lua.lua_isnoneornil(L, 2)) {
			gpioMem[i] = getN(L, 2, 0) | 0;
			return 0;
		}
		return pushNum(L, gpioMem[i]);
	}

	function api_extcmd(L) {
		// Reserved for future shell interaction (e.g. reset).
		return 0;
	}

	function api_sfx(L) {
		return 0; // no audio in the PDA web shell for now
	}

	function api_mget(L) {
		var x = getN(L, 1, 0) | 0;
		var y = getN(L, 2, 0) | 0;
		if (x < 0 || x >= WIDTH || y < 0 || y >= 64) { return pushNum(L, 0); }
		return pushNum(L, mapMem[y * WIDTH + x]);
	}

	function api_mset(L) {
		var x = getN(L, 1, 0) | 0;
		var y = getN(L, 2, 0) | 0;
		var v = getN(L, 3, 0) | 0;
		if (x < 0 || x >= WIDTH || y < 0 || y >= 64) { return 0; }
		mapMem[y * WIDTH + x] = v;
		return 0;
	}

	function api_sprset(L) {
		var n = getN(L, 1, 0) | 0;
		var sx = (n % 16) * 8;
		var sy = Math.floor(n / 16) * 8;
		for (var row = 0; row < 8; row++) {
			var line = getS(L, 2 + row, '');
			for (var col = 0; col < 8; col++) {
				var ch = line.charAt(col);
				var c = parseInt(ch, 16);
				if (isNaN(c)) { c = 0; }
				gfx[(sy + row) * WIDTH + sx + col] = c;
			}
		}
		return 0;
	}

	function api_add(L) {
		var n = lua.lua_rawlen(L, 1);
		var top = lua.lua_gettop(L);
		for (var i = 2; i <= top; i++) {
			lua.lua_pushvalue(L, i);
			lua.lua_rawseti(L, 1, n + (i - 1));
		}
		lua.lua_pushvalue(L, 1);
		return 1;
	}

	function api_del(L) {
		var n = lua.lua_rawlen(L, 1);
		var i = getN(L, 2, -1);
		if (i < 1) { i = 1; }
		if (i > n) { i = n; }
		if (n < 1) {
			lua.lua_pushnil(L);
			return 1;
		}
		lua.lua_rawgeti(L, 1, i);
		var removed = lua.lua_gettop(L);
		for (var j = i; j < n; j++) {
			lua.lua_rawgeti(L, 1, j + 1);
			lua.lua_rawseti(L, 1, j);
		}
		lua.lua_pushnil(L);
		lua.lua_rawseti(L, 1, n);
		lua.lua_pushvalue(L, removed);
		lua.lua_remove(L, removed);
		return 1;
	}

	function api_foreach(L) {
		lua.lua_pushnil(L);
		while (lua.lua_next(L, 1) !== 0) {
			lua.lua_pushvalue(L, 2);          // fn
			lua.lua_pushvalue(L, -2);         // value
			if (lua.lua_pcall(L, 1, 0, 0) !== LUA_OK) { return 0; }
		}
		return 0;
	}

	function registerAPI(vm) {
		var fns = {
			'cls': api_cls, 'pset': api_pset, 'pget': api_pget, 'spr': api_spr,
			'sspr': api_sspr, 'rect': api_rect, 'rectfill': api_rectfill,
			'circ': api_circ, 'circfill': api_circfill, 'line': api_line,
			'print': api_print, 'btn': api_btn, 'btnp': api_btnp,
			'rnd': api_rnd, 'srand': api_srand, 'flr': api_flr, 'ceil': api_ceil,
			'abs': api_abs, 'min': api_min, 'max': api_max, 'mid': api_mid,
			'sin': api_sin, 'cos': api_cos, 'atan2': api_atan2, 'sqrt': api_sqrt,
			'sgn': api_sgn, 'time': api_time, 't': api_time, 'stat': api_stat,
			'gpio': api_gpio, 'extcmd': api_extcmd, 'sfx': api_sfx, 'music': api_sfx,
			'mget': api_mget, 'mset': api_mset, 'camera': api_camera, 'sprset': api_sprset,
			'add': api_add, 'del': api_del, 'foreach': api_foreach
		};
		for (var name in fns) {
			if (Object.prototype.hasOwnProperty.call(fns, name)) {
				vm.set(name, fns[name]);
			}
		}
	}

	// ---- Lua VM wrapper ------------------------------------------------------
	function LuaVM() {
		this.S = lauxlib.luaL_newstate();
		lualib.luaL_openlibs(this.S);
		this.lastError = '';
	}

	LuaVM.prototype.readError = function () {
		var p = lua.lua_tostring(this.S, -1);
		this.lastError = p ? to_jsstring(p) : 'unknown lua error';
		lua.lua_pop(this.S, 1);
	};

	LuaVM.prototype.execute = function (code) {
		var S = this.S;
		var src = to_luastring(code);
		var r = lauxlib.luaL_loadbuffer(S, src, src.length, to_luastring('cart'));
		if (r !== LUA_OK) {
			this.readError();
			return false;
		}
		r = lua.lua_pcall(S, 0, 0, 0);
		if (r !== LUA_OK) {
			this.readError();
			return false;
		}
		return true;
	};

	LuaVM.prototype.set = function (name, fn) {
		lua.lua_pushjsfunction(this.S, fn);
		lua.lua_setglobal(this.S, to_luastring(name));
	};

	LuaVM.prototype.call = function (name) {
		var S = this.S;
		lua.lua_getglobal(S, to_luastring(name));
		if (lua.lua_isnil(S, -1)) {
			lua.lua_pop(S, 1);
			return null; // not defined: fine
		}
		if (!lua.lua_isfunction(S, -1)) {
			lua.lua_pop(S, 1);
			return null;
		}
		var r = lua.lua_pcall(S, 0, 0, 0);
		if (r !== LUA_OK) {
			this.readError();
			return false;
		}
		return true;
	};

	LuaVM.prototype.close = function () {
		if (this.S) {
			lua.lua_close(this.S);
			this.S = null;
		}
	};

	// ---- cartridge handling --------------------------------------------------
	function extractLua(src) {
		var i = src.indexOf('__lua__');
		var code;
		if (i < 0) {
			code = src;
		} else {
			code = src.substring(i + 7);
			var j = code.search(/\n__[a-zA-Z]+__/);
			if (j >= 0) { code = code.substring(0, j); }
		}
		return transpile(code);
	}

	// Adapted under MIT from pico8-web-emulator (Brooklyn Baylis).
	function transpile(luaCode) {
		luaCode = luaCode.replace(/!=/g, '~=');

		luaCode = luaCode.replace(
			/([a-zA-Z_][\w]*(?:\.[a-zA-Z_][\w]*)*)\s*([-+*/%])=\s*([^\s;]+)/g,
			function (match, varName, op, value) {
				return varName + ' = ' + varName + ' ' + op + ' ' + value;
			}
		);

		var lines = luaCode.split('\n');
		var processed = lines.map(function (line) {
			var trimmed = line.trim();
			var match = trimmed.match(/^if\s*\((.*?)\)\s+(.+)$/);
			if (match && trimmed.indexOf('then') < 0) {
				var condition = match[1];
				var body = match[2];
				var statements = body.split(/\s+(?=[a-zA-Z_][\w]*\s*=)/).map(function (s) {
					return '  ' + s.trim();
				});
				return 'if ' + condition + ' then\n' + statements.join('\n') + '\nend';
			}
			return line;
		});
		luaCode = processed.join('\n');

		luaCode = luaCode.replace(/if\s*\(([^)]+)\)\s*return/g, 'if $1 then return end');

		return luaCode;
	}

	// ---- frame loop ----------------------------------------------------------
	function blit() {
		var data = imgData.data;
		for (var i = 0; i < WIDTH * HEIGHT; i++) {
			var c = fb[i];
			var o = i * 4;
			data[o] = PALETTE_RGB[c * 4];
			data[o + 1] = PALETTE_RGB[c * 4 + 1];
			data[o + 2] = PALETTE_RGB[c * 4 + 2];
			data[o + 3] = 255;
		}
		ctx.putImageData(imgData, 0, 0);
	}

	function frame(ts) {
		if (!running) { rafId = null; return; }
		rafId = null;
		var dt = ts - lastTs;
		lastTs = ts;
		acc += dt;
		var steps = 0;
		while (acc >= FRAME_MS && steps < 4) {
			prevKey = keyState.slice();

			var up = vm.call('_update');
			if (up === false) { fail(vm.lastError); return; }

			var dr = vm.call('_draw');
			if (dr === false) { fail(vm.lastError); return; }

			blit();
			acc -= FRAME_MS;
			steps++;

			if (gpioMem[0] > 0) {
				var v = gpioMem[0];
				gpioMem[0] = 0;
				if (onGpio) { onGpio(0, v); }
			}
		}
		if (steps >= 4) { acc = 0; }
		rafId = requestAnimationFrame(frame);
	}

	function fail(msg) {
		lastError = msg;
		running = false;
		if (onError) { onError(msg); }
	}

	function resetState() {
		gfx.fill(0);
		mapMem.fill(0);
		fb.fill(0);
		camX = 0;
		camY = 0;
		keyState.fill(false);
		prevKey.fill(false);
		gpioMem.fill(0);
		rng = 0x524F43;
		lastError = '';
	}

	function bind(el) {
		canvasEl = el;
		if (!el) { return; }
		ctx = el.getContext('2d');
		ctx.imageSmoothingEnabled = false;
		imgData = ctx.createImageData(WIDTH, HEIGHT);
	}

	function loadCart(src, el) {
		if (!FW) { return; }
		if (rafId !== null) {
			cancelAnimationFrame(rafId);
			rafId = null;
		}
		if (vm) {
			vm.close();
			vm = null;
		}
		resetState();
		bind(el);
		if (!el) { return; }

		startTime = performance.now();
		lastTs = performance.now();
		acc = 0;

		var code = extractLua(String(src));
		vm = new LuaVM();
		registerAPI(vm);

		if (!vm.execute(code)) {
			fail(vm.lastError);
			return;
		}
		var r = vm.call('_init');
		if (r === false) {
			fail(vm.lastError);
			return;
		}

		running = true;
		rafId = requestAnimationFrame(frame);
	}

	function destroy() {
		running = false;
		if (rafId !== null) {
			cancelAnimationFrame(rafId);
			rafId = null;
		}
		if (vm) {
			vm.close();
			vm = null;
		}
	}

	function setButton(i, down) {
		keyState[i] = !!down;
	}

	// ---- public API ----------------------------------------------------------
	var api = {
		load: loadCart,
		destroy: destroy,
		bind: bind,
		setButton: setButton,
		isRunning: function () { return running; },
		getLastError: function () { return lastError; }
	};
	Object.defineProperty(api, 'onGpio', {
		get: function () { return onGpio; },
		set: function (v) { onGpio = v; }
	});
	Object.defineProperty(api, 'onError', {
		get: function () { return onError; },
		set: function (v) { onError = v; }
	});
	global.PICO8 = api;
})(window);
