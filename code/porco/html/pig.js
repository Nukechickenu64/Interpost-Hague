var scrollbar;
try {
	scrollbar = new Control.ScrollBar('scrollbar_content', 'scrollbar_track', 'scrollbtnup', 'scrollbtndown');
} catch(error) {
	scrollbar = {
		scrollBy: function() {},
		scrollTo: function() {},
		recalculateLayout: function() {},
		lastscrollTop: 0
	};
}
var cureval = 0;
var elem = document.getElementById('scrollbar_content');
var elem_scrollbar = document.getElementById('scrollbar_track');
var E = document.getElementById('scrollbar_container');

function stopScrollRepeat() {
	if(cureval !== 0) {
		window.self.clearInterval(cureval);
		cureval = 0;
	}
}

function scrollup() {
	scrollbar.scrollBy(-24);
}

function scrolldown() {
	scrollbar.scrollBy(24);
}

function startScrollRepeat(event, amount, callback) {
	scrollbar.scrollBy(amount);
	stopScrollRepeat();
	cureval = window.self.setInterval(callback, 250);
	event.stop();
}

$('scrollbtndown').observe('mousedown', function(event) {
		startScrollRepeat(event, 24, scrolldown);
});

$('scrollbtndown').observe('mouseup', function(event) {
	stopScrollRepeat();
	event.stop();
});

$('scrollbtnup').observe('mousedown', function(event) {
	startScrollRepeat(event, -24, scrollup);
});

$('scrollbtnup').observe('mouseup', function(event) {
	stopScrollRepeat();
	event.stop();
});

function redirect() {
	byondCommand('doneRsc');
}

function byondCommand(command) {
	window.location = 'byond://winset?command=' + encodeURIComponent(command);
}

function cancelLink(event) {
	if(event) {
		event.returnValue = false;
		event.cancelBubble = true;
	}
	return false;
}

function FI(tmpImg) {
	tmpImg.src += '?m=' + Math.floor(Math.random() * 10000);
}

function fixScrollbar() {
	if(scrollbar.lastscrollTop !== elem.scrollTop) {
		scrollbar.scrollTo(elem.scrollTop, 0);
	}
}

function imagesReload() {
	var images = document.querySelectorAll('img');

	for(var index = 0; index < images.length; index++) {
		images[index].onerror = function() {
			FI(this);
		};
	}
}

function generateButton() {
	imagesReload();
}

function addel(content, selector) {
	var selected = document.querySelector(selector);

	if(!selected || selected.innerHTML === content) {
		return;
	}

	selected.innerHTML = content;
	scrollbar.recalculateLayout();
}

function changel(content, selector) {
	var selected = document.querySelector(selector);

	if(!selected) {
		return;
	}

	selected.onclick = function(event) {
		InputMsg(content);
		if(event) {
			event.returnValue = false;
			event.cancelBubble = true;
		}
		return false;
	};
	if(selected.parentNode && selected.parentNode.tagName && selected.parentNode.tagName.toLowerCase() === 'a') {
		selected.parentNode.onclick = selected.onclick;
	}
	scrollbar.recalculateLayout();
}

function InputMsg(msgtext) {
	if(msgtext !== '' && msgtext !== null) {
		msgtext = msgtext.split('$').join('<br>');
	}

	elem.innerHTML = msgtext;
	scrollbar.recalculateLayout();
}

function change(id, content) {
	var selected = document.getElementById(id);

	if(!selected) {
		return;
	}

	selected.innerHTML = content;
	scrollbar.recalculateLayout();
}

elem.onscroll = fixScrollbar;
elem.onload = fixScrollbar;
window.onload = function() {
	redirect();
	imagesReload();
	var chromeLink = document.getElementById('chrome-link');
	var optionsLink = document.getElementById('options-link');
	if(chromeLink) {
		chromeLink.onclick = function(event) {
			InputMsg('Stats are shown in the main panel.');
			return cancelLink(event);
		};
	}
	if(optionsLink) {
		optionsLink.onclick = function(event) {
			InputMsg('');
			return cancelLink(event);
		};
	}
};
