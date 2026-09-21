var scrollbar = new Control.ScrollBar('scrollbar_content', 'scrollbar_track', 'scrollbtnup', 'scrollbtndown');
var cureval = 0;
var elem = document.getElementById('scrollbar_content');
var elem_scrollbar = document.getElementById('scrollbar_track');
var E = document.getElementById('scrollbar_container');

function byondCommand(command) {
	window.location = 'byond://winset?command=' + encodeURIComponent(command);
}

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

	selected.onclick = function() {
		byondCommand('button');
		InputMsg(content);
		return false;
	};
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
}

elem.onscroll = fixScrollbar;
elem.onload = fixScrollbar;
window.onload = redirect;

var p = document.getElementById('pig');
var n = document.getElementById('note');

if(p) {
	p.onclick = function() {
		byondCommand('Who');
		return false;
	};
}

if(n) {
	n.onclick = function() {
		byondCommand('heartpig');
		return false;
	};
}