// Keep the internal screen in place while NanoUI refreshes its contents.
(function () {
    var previousPage = null;
    var scrollTop = 0;
    var device = null;
    var windowId = null;
    var drag = null;
    var dragTimer = null;

    function flushDrag() {
        dragTimer = null;
        if (!drag || !drag.position) { return; }
        var x = Math.round(drag.position.x);
        var y = Math.round(drag.position.y);
        if (drag.windowId) {
            // Match TGUI's client-side winset transport; no server round trip per move.
            window.location.href = 'byond://winset?' + encodeURIComponent(drag.windowId + '.pos') + '=' + encodeURIComponent(x + ',' + y);
        } else {
            // Standalone browser previews move the device within the page.
            $('.pda-case').css({ left: x, top: y });
        }
        drag.position = null;
    }

    function moveDrag(event) {
        if (!drag) { return; }
        if (event.type === 'mousemove' && typeof event.buttons === 'number' && !(event.buttons & 1)) {
            stopDrag();
            return;
        }
        var x = drag.left + event.screenX - drag.x;
        var y = drag.top + event.screenY - drag.y;
        if (!drag.windowId) {
            x = Math.max(0, Math.min($(window).width() - $('.pda-case').width(), x));
            y = Math.max(0, Math.min($(window).height() - $('.pda-case').height(), y));
        }
        drag.position = { x: x, y: y };
        if (dragTimer === null) { dragTimer = window.setTimeout(flushDrag, 16); }
        event.preventDefault();
    }

    function stopDrag(event) {
        if (!drag) { return; }
        if (event && event.type === 'mouseup') { moveDrag(event); }
        if (dragTimer !== null) { window.clearTimeout(dragTimer); }
        flushDrag();
        var handle = drag.handle;
        drag = null;
        $(document).off('mousemove.pdaDrag mouseup.pdaDrag keydown.pdaDrag');
        $(window).off('blur.pdaDrag');
        $(handle).off('losecapture.pdaDrag').removeClass('pda-dragging');
        if (handle.releaseCapture) { handle.releaseCapture(); }
    }

    $(document).on('mousedown.pdaDrag', '.pda-drag-handle', function (event) {
        if (event.which !== 1) { return; }
        stopDrag();
        var position = $('.pda-case').position();
        drag = {
            handle: this, windowId: windowId, x: event.screenX, y: event.screenY,
            left: windowId ? (typeof window.screenLeft === 'number' ? window.screenLeft : window.screenX) : position.left,
            top: windowId ? (typeof window.screenTop === 'number' ? window.screenTop : window.screenY) : position.top
        };
        $(this).addClass('pda-dragging').on('losecapture.pdaDrag', stopDrag);
        $(document).on('mousemove.pdaDrag', moveDrag).on('mouseup.pdaDrag', stopDrag).on('keydown.pdaDrag', function (key) {
            if (key.which === 27) { stopDrag(); }
        });
        $(window).on('blur.pdaDrag', stopDrag);
        // IE's mouse capture keeps dragging/release working outside the browser bounds.
        if (this.setCapture) { this.setCapture(); }
        event.preventDefault();
    });

    function fitDevice() {
        if (!device) { return; }
        var baseWidth = device.screenWidth * 30 + 64;
        var baseHeight = device.screenHeight * 30 + 64;
        var scale = Math.max(0.25, Math.min(1, ($(window).width() - 4) / baseWidth, ($(window).height() - 4) / baseHeight));
        var width = baseWidth * scale;
        var height = baseHeight * scale;
        $('.pda-case').css({ width: width, height: height, left: ($(window).width() - width) / 2, top: ($(window).height() - height) / 2 });
        $('.pda-screen').css({ left: 32 * scale, top: 32 * scale, width: device.screenWidth * 30 * scale, height: device.screenHeight * 30 * scale });
    }
    $(window).on('resize.pda', fitDevice);

    NanoStateManager.addBeforeUpdateCallback('pdaScroll', function (update) {
        var page = update.data.mode + ':' + (update.data.active_conversation || '');
        scrollTop = page === previousPage ? ($('.pda-page').scrollTop() || 0) : 0;
        previousPage = page;
        return update;
    });

    NanoStateManager.addAfterUpdateCallback('pdaScroll', function (update) {
        windowId = update.config && update.config.window || null;
        if (update.data.device && (!device || device.state !== update.data.device.state)) {
            device = update.data.device;
            $('.pda-case').css('color', device.foreground);
            $('.pda-screen').css({
                backgroundColor: device.background, borderColor: device.edge
            });
            fitDevice();
        }
        $('.pda-page').scrollTop(scrollTop);
        $('.pda-nav .link, .pda-hardware .link, .pda-close .link').each(function () {
            var link = $(this);
            link.attr('aria-label', link.parent().attr('title'));
            link.attr('aria-pressed', link.hasClass('selected') ? 'true' : 'false');
        });
        $('.pda-case .link').attr('role', 'button');
        $('.pda-case .linkActive').attr('tabindex', '0').off('keydown.pda').on('keydown.pda', function (event) {
            if (event.which === 13 || event.which === 32) {
                event.preventDefault();
                $(this).trigger('click');
            }
        });
        return update;
    });
}());
