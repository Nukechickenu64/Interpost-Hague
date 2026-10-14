// PICO-8 app glue for the PDA NanoUI shell.
// Boots the PICO8 runtime when the PDA is in mode 8 (cartridge running),
// pipes keyboard/touch input to it, and reports high scores to the server
// when a cartridge posts a value on gpio pin 0.
(function () {
	var cartName = null;   // cart currently running, null when on the menu
	var epoch = null;      // server epoch of the running cart
	var canvas = null;     // overlay canvas appended inside .p8-screen

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

	function submitScore(value) {
		if (!cartName || !value || !isFinite(value) || value <= 0) { return; }
		window.location.href = NanoUtility.generateHref({
			'choice': 'p8_score',
			'cart': cartName,
			'score': Math.floor(value)
		});
	}

	function pressButton(btn, down) {
		if (window.PICO8) { window.PICO8.setButton(btn, down); }
	}

	function clearInputs() {
		if (window.PICO8) {
			for (var i = 0; i < 8; i++) { window.PICO8.setButton(i, false); }
		}
	}

	function attachInput() {
		$(document).off('keydown.pico8 keyup.pico8 mousedown.pico8 mouseup.pico8 touchstart.pico8 touchend.pico8 touchcancel.pico8');

		$(document).on('keydown.pico8', function (e) {
			if (!cartName) { return; }
			var btn = KEYMAP[e.which];
			if (btn !== undefined) {
				pressButton(btn, true);
				e.preventDefault();
			}
		}).on('keyup.pico8', function (e) {
			if (!cartName) { return; }
			var btn = KEYMAP[e.which];
			if (btn !== undefined) {
				pressButton(btn, false);
				e.preventDefault();
			}
		});

		// On-screen control pad: .p8-pad-btn[data-btn=N]
		$(document).on('mousedown.pico8 touchstart.pico8', '.p8-pad-btn[data-btn]', function (e) {
			var btn = parseInt($(this).attr('data-btn'), 10);
			pressButton(btn, true);
			e.preventDefault();
		}).on('mouseup.pico8 mouseleave.pico8 touchend.pico8 touchcancel.pico8', '.p8-pad-btn[data-btn]', function (e) {
			var btn = parseInt($(this).attr('data-btn'), 10);
			pressButton(btn, false);
			e.preventDefault();
		});
	}

	function ensureCanvas() {
		if (!canvas) {
			canvas = document.createElement('canvas');
			canvas.className = 'p8-screen-canvas';
			canvas.width = 128;
			canvas.height = 128;
			canvas.tabIndex = 0;
		}
		// Re-anchor after NanoUI re-renders the screen holder.
		if (canvas.parentNode !== null) {
			canvas.parentNode.removeChild(canvas);
		}
		var holder = $('.p8-screen').get(0);
		if (holder) {
			holder.appendChild(canvas);
		}
		return canvas;
	}

	function removeCanvas() {
		if (canvas) {
			if (canvas.parentNode) {
				canvas.parentNode.removeChild(canvas);
			}
			canvas = null;
		}
	}

	function boot(info) {
		if (!window.PICO8) { return; }
		cartName = info.name;
		epoch = info.epoch;
		var el = ensureCanvas();
		if (!el) { return; }
		attachInput();
		window.PICO8.onGpio = function (pin, value) {
			if (pin === 0) { submitScore(value); }
		};
		window.PICO8.onError = function (msg) {
			$('.p8-error').text('err: ' + msg).show();
		};
		window.PICO8.load(info.source, el);
	}

	function halt() {
		if (window.PICO8) {
			window.PICO8.onGpio = null;
			window.PICO8.onError = null;
			window.PICO8.destroy();
		}
		clearInputs();
		$(document).off('keydown.pico8 keyup.pico8 mousedown.pico8 mouseup.pico8 touchstart.pico8 touchend.pico8 touchcancel.pico8');
		removeCanvas();
		cartName = null;
		epoch = null;
	}

	// Hook NanoUI updates for the PDA UI.
	NanoStateManager.addAfterUpdateCallback('pico8pda', function (update) {
		var p8 = update.data && update.data.pico8;
		var mode = update.data ? update.data.mode : null;

		if (mode !== 8 || !p8 || !p8.running) {
			if (cartName !== null) { halt(); }
			return update;
		}

		if (!window.PICO8) { return update; }

		if (cartName === p8.running && epoch === p8.epoch) {
			// Same cart still running; just surface any runtime error.
			if (!window.PICO8.isRunning() && window.PICO8.getLastError()) {
				$('.p8-error').text('err: ' + window.PICO8.getLastError()).show();
			}
			return update;
		}

		// New cart or epoch bump: full reboot, re-anchoring the canvas.
		halt();
		$('.p8-error').text('').hide();
		boot({ name: p8.running, source: p8.source, epoch: p8.epoch });

		return update;
	});
}());