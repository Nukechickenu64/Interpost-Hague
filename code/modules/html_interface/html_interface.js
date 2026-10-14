var is_loading								= false;
var load_count								= 0;

// Keep physical window chrome outside the portion replaced by this framework.
function layoutRoot() { return window.DeviceUI ? $(window.DeviceUI.content()) : $("body"); }

function onload()
{
	if (!is_loading)
	{
		var count							= ++load_count;
		is_loading							= true;
		layoutRoot().html("");

		window.location.href				= "byond://?src=" + hSrc + "&html_interface_action=onload";
		
		// The request may fail which would prevent the player from refreshing the screen again. Try to detect this retry.
		setTimeout(function()
		{
			if (count == load_count && is_loading && layoutRoot().html() == "")
			{
				is_loading					= false;
				onload();
			}
		}, 500);
	}
}

$(document).ready(function()
{
	$(document).on("keydown", function(e)
	{
		if (!e.ctrlKey && e.which == 116)
		{
			e.preventDefault();

			onload();
		}
	});

	onload();
});

function fixText(text)						{ return text.replace(/ÿ/g, ""); }

function setTitle(new_title)				{ $("title").html(fixText(new_title)); $(window).trigger("onUpdateTitle"); }
function updateLayout(new_html)				{ layoutRoot().html(fixText(new_html)); $(window).trigger("onUpdateLayout"); setTimeout(function(){ is_loading = false; }, 200); }
function updateContent(id, new_html)		{ $("#" + id).html(fixText(new_html)); $(window).trigger("onUpdateContent"); }
