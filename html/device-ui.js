/* Shared physical window chrome. ES5/IE compatible; no framework dependency. */
(function () {
    'use strict';
    var config, frame, content, gesture, timer;

    function winset(property, value) {
        if (!config.window) { return; }
        window.location.href = 'byond://winset?' + encodeURIComponent(config.window + '.' + property) + '=' + encodeURIComponent(value);
    }
    function flush() {
        timer = null;
        if (!gesture || !gesture.next) { return; }
        var p = gesture.next;
        if (config.window) {
            winset(gesture.resize ? 'size' : 'pos', p[0] + ',' + p[1]);
        } else {
            frame.style[gesture.resize ? 'width' : 'left'] = p[0] + 'px';
            frame.style[gesture.resize ? 'height' : 'top'] = p[1] + 'px';
            frame.style.right = frame.style.bottom = 'auto';
        }
        gesture.next = null;
    }
    function move(e) {
        if (!gesture) { return; }
        if (e.type === 'mousemove' && typeof e.buttons === 'number' && !(e.buttons & 1)) { stop(); return; }
        var x = Math.round(gesture.left + e.screenX - gesture.x);
        var y = Math.round(gesture.top + e.screenY - gesture.y);
        if (gesture.resize) { x = Math.max(320, x); y = Math.max(240, y); }
        gesture.next = [x, y];
        if (timer === null) { timer = window.setTimeout(flush, 16); }
        e.preventDefault();
    }
    function stop(e) {
        if (!gesture) { return; }
        if (e && e.type === 'mouseup') { move(e); }
        if (timer !== null) { window.clearTimeout(timer); }
        flush();
        var handle = gesture.handle;
        gesture = null;
        document.removeEventListener('mousemove', move);
        document.removeEventListener('mouseup', stop);
        window.removeEventListener('blur', stop);
        handle.removeEventListener('losecapture', stop);
        if (handle.releaseCapture) { handle.releaseCapture(); }
    }
    function start(e, resize) {
        if (e.button !== 0) { return; }
        stop();
        var rect = frame.getBoundingClientRect();
        gesture = {
            handle: e.currentTarget, resize: resize, x: e.screenX, y: e.screenY,
            left: resize ? (config.window ? window.innerWidth : rect.width) : (config.window ? window.screenLeft : rect.left),
            top: resize ? (config.window ? window.innerHeight : rect.height) : (config.window ? window.screenTop : rect.top),
            next: null
        };
        timer = null;
        document.addEventListener('mousemove', move);
        document.addEventListener('mouseup', stop);
        window.addEventListener('blur', stop);
        gesture.handle.addEventListener('losecapture', stop);
        if (gesture.handle.setCapture) { gesture.handle.setCapture(); }
        e.preventDefault();
    }
    function mount() {
        if (frame) { return content; }
        var meta = document.querySelector('meta[name="device-screen"]');
        if (!meta || !document.body) { return document.body; }
        config = JSON.parse(meta.content);
        document.documentElement.className += ' device-root';
        document.body.className += ' device-ui device-' + config.kind;
        frame = document.createElement('div');
        frame.id = 'device-frame';
        frame.innerHTML = '<div id="device-drag" class="device-hardware" title="Drag window"><span id="device-name"></span><span class="device-vents" aria-hidden="true"></span></div>' +
            '<button id="device-close" class="device-hardware" type="button" aria-label="Close window" title="Close window">&#215;</button>' +
            '<div id="device-glass"><div id="device-content"></div><div id="device-reflection" aria-hidden="true"></div></div>' +
            '<div class="device-bottom device-hardware"><span id="device-indicator" aria-hidden="true"></span><span class="device-grille" aria-hidden="true"></span></div>' +
            '<div class="device-screw device-screw-left" aria-hidden="true"></div><div class="device-screw device-screw-right" aria-hidden="true"></div>' +
            '<button id="device-resize" class="device-hardware" type="button" aria-label="Resize window" title="Drag to resize; arrow keys to adjust">&#9698;</button>';
        content = frame.querySelector('#device-content');
        while (document.body.firstChild) { content.appendChild(document.body.firstChild); }
        document.body.appendChild(frame);
        frame.querySelector('#device-name').textContent = config.name;
        frame.querySelector('#device-drag').addEventListener('mousedown', function (e) { start(e, false); });
        frame.querySelector('#device-resize').addEventListener('mousedown', function (e) { start(e, true); });
        frame.querySelector('#device-resize').addEventListener('keydown', function (e) {
            var dx = e.keyCode === 39 ? 20 : e.keyCode === 37 ? -20 : 0;
            var dy = e.keyCode === 40 ? 20 : e.keyCode === 38 ? -20 : 0;
            if (dx || dy) { winset('size', Math.max(320, window.innerWidth + dx) + ',' + Math.max(240, window.innerHeight + dy)); e.preventDefault(); }
        });
        frame.querySelector('#device-close').addEventListener('click', function () {
            stop();
            if (config.closeHref) { window.location.href = config.closeHref; }
            else if (config.closeCommand) { window.location.href = 'byond://winset?command=' + encodeURIComponent(config.closeCommand); }
        });
        document.addEventListener('keydown', function (e) { if (e.keyCode === 27) { stop(); } });
        return content;
    }
    window.DeviceUI = { mount: mount, content: function () { return mount(); } };
    if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', mount); }
    else { mount(); }
}());
