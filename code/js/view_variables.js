function updateSearch() {
	var filter_text = document.getElementById('filter');
	if (!filter_text) return;
	var filter = (filter_text.value || "").toLowerCase();

	var vars_ol = document.getElementById('vars');
	if (!vars_ol) return;
	var lis = vars_ol.children;
	// the above line can be changed to vars_ol.getElementsByTagName("li") to filter child lists too
	// potential todo: implement a per-admin toggle for this

	for (var i = 0; i < lis.length; i++) {
		var li = lis[i];
		var text = (li.textContent || li.innerText || "").toLowerCase();
		if (filter === "" || text.indexOf(filter) !== -1) {
			li.style.display = ""; // default display for li
		} else {
			li.style.display = "none";
		}
	}
}

function selectTextField() {
	var filter_text = document.getElementById('filter');
	filter_text.focus();
	filter_text.select();
}

function loadPage(list) {
	if (!list || !list.options || list.selectedIndex < 0) return;
	var url = list.options[list.selectedIndex].value;
	if (!url) return;
	window.location.href = url;
	list.selectedIndex = 0;
}
