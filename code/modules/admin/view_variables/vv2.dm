// vv2.dm - Modern variable viewer system for BYOND

// Usage: call client.proc/vv2_view_variables(datum/D) to open the new viewer

/client/proc/vv2_view_variables(datum/D in world)
	set category = "Debug"
	set name = "View Variables 2"

	if(!check_rights(0))
		return
	if(!D)
		return

	var/icon/sprite
	if(istype(D, /atom))
		var/atom/A = D
		if(A.icon && A.icon_state)
			sprite = icon(A.icon, A.icon_state)
			usr << browse_rsc(sprite, "vv2_sprite.png")

	var/html = vv2_generate_html(D, sprite)
	usr << browse(html, "window=vv2_variables\ref[D];size=600x700;focus=1")

// Generates the HTML for the new variable viewer
/proc/vv2_generate_html(datum/D, sprite)
	var/title = "[D] (\ref[D] - [D.type])"
	var/vars_html = vv2_make_var_list(D)
	var/options_html = hascall(D, "get_view_variables_options") ? D.get_view_variables_options() : ""
	var/header_html = hascall(D, "get_view_variables_header") ? D.get_view_variables_header() : "<b>[D]</b>"
	var/sprite_html = sprite ? "<td><img src='vv2_sprite.png'></td>" : ""
	return {"
	<html><head>
	<title>[title]</title>
	<style>
	body { font-family: Verdana, sans-serif; font-size: 10pt; }
	.value { font-family: 'Courier New', monospace; font-size: 9pt; }
	input, select { font-size: 10pt; }
	</style>
	<script>
	function updateSearch() {
		var filter_text = document.getElementById('filter');
		if (!filter_text) return;
		var filter = (filter_text.value || '').toLowerCase();
		var vars_ol = document.getElementById('vars');
		if (!vars_ol) return;
		var lis = vars_ol.getElementsByTagName('li');
		for (var i = 0; i < lis.length; i++) {
			var li = lis[i];
			var text = (li.textContent || li.innerText || '').toLowerCase();
			li.style.display = (filter === '' || text.indexOf(filter) !== -1) ? '' : 'none';
		}
	}
	function loadPage(list) {
		if (!list || !list.options || list.selectedIndex < 0) return;
		var url = list.options[list.selectedIndex].value;
		if (!url) return;
		window.location.href = url;
		list.selectedIndex = 0;
	}
	window.onload = function() {
		var filter = document.getElementById('filter');
		if(filter) { filter.focus(); filter.select(); }
	};
	</script>
	</head>
	<body tabindex='0'>
	<div align='center'>
	<table width='100%'><tr>
	<td width='50%'>
	<table align='center' width='100%'><tr>
	[sprite_html]
	<td><div align='center'>[header_html]</div></td>
	</tr></table>
	</td>
	<td width='50%'>
	<div align='center'>
	<a href='?_src_=vv2;datumrefresh=\ref[D]'>Refresh</a>
	<form>
	<select name='file' size='1' onchange='loadPage(this)' style='background-color:#fff;'>
	<option>Select option</option>
	<option></option>
	<option value='?_src_=vv2;mark_object=\ref[D]'>Mark Object</option>
	<option value='?_src_=vv2;call_proc=\ref[D]'>Call Proc</option>
	[options_html]
	</select>
	</form>
	</div>
	</td>
	</tr></table>
	</div>
	<hr/>
	<font size='1'>
	<b>E</b> - Edit, tries to determine the variable type by itself.<br/>
	<b>C</b> - Change, asks you for the var type first.<br/>
	<b>M</b> - Mass modify: changes this variable for all objects of this type.<br/>
	</font>
	<hr/>
	<table width='100%'><tr>
	<td width='20%'><div align='center'><b>Search:</b></div></td>
	<td width='80%'><input type='text' id='filter' name='filter_text' value='' onkeyup='updateSearch()' oninput='updateSearch()' style='width:100%;' /></td>
	</tr></table>
	<hr/>
	<ol id='vars'>[vars_html]</ol>
	</body></html>
	"}

// Generates the variable list HTML
/proc/vv2_make_var_list(datum/D)
	. = list()
	var/list/variables = hascall(D, "get_variables") ? D.get_variables() : list()
	variables = sortList(variables)
	for(var/x in variables)
		. += vv2_make_var_entry(D, x, hascall(D, "get_variable_value") ? D.get_variable_value(x) : null)
	return jointext(., null)

// Generates a single variable entry
/proc/vv2_make_var_entry(datum/D, varname, value)
	var/valuestr = vv2_make_value(value, varname)
	return "<li><b>[varname]</b> = <span class='value'>[valuestr]</span></li>"

// Generates a value string for display
/proc/vv2_make_value(value, varname = "*")
	if(isnull(value)) return "null"
	if(istext(value)) return "\"[value]\""
	if(isicon(value)) return "[value]"
	if(isfile(value)) return "'[value]'"
	if(istype(value, /datum)) return "<a href='?_src_=vv2;Vars=\ref[value]'>\ref[value]</a> - [value:type]"
	if(istype(value, /client)) return "<a href='?_src_=vv2;Vars=\ref[value]'>\ref[value]</a> - [value:type]"
	if(islist(value)) return "/list ([value:len])"
	return "[value]"
