// Shared styled HTML wrapper for browser windows, matching the diegetic context menu look

// Build a styled HTML page with a title and provided body content.
// - title: small uppercase header shown at the top
// - body_html: inner HTML for the page body (already sanitized/encoded by caller if needed)
// Returns a complete HTML document string ready for browse()
/proc/_ui_remap_colors(var/t as text)
    if(!t) return ""
    // Map legacy low-contrast colors to bright theme-friendly ones
    var/list/pairs = list(
        "color='black'"="color='#d7f6ff'",
        "color=\"black\""="color='#d7f6ff'",
        "color = 'black'"="color='#d7f6ff'",
        "color = \"black\""="color='#d7f6ff'",
        "color='blue'"="color='#8fe3ff'",
        "color=\"blue\""="color='#8fe3ff'",
        "color='maroon'"="color='#ff9a9a'",
        "color=\"maroon\""="color='#ff9a9a'",
        "color='red'"="color='#ff7a7a'",
        "color=\"red\""="color='#ff7a7a'",
        "color='green'"="color='#9fff9f'",
        "color=\"green\""="color='#9fff9f'",
        "color='orange'"="color='#ffb86b'",
        "color=\"orange\""="color='#ffb86b'",
        "color='grey'"="color='#b7c2d0'",
        "color=\"grey\""="color='#b7c2d0'",
        "color='gray'"="color='#b7c2d0'",
        "color=\"gray\""="color='#b7c2d0'",
        // Common hex usages in legacy UIs
        "color=#18743e"="color='#9fff9f'",
        "color = #18743e"="color='#9fff9f'",
        "color=#990000"="color='#ff7a7a'",
        "color = #990000"="color='#ff7a7a'",
        "color=#787700"="color='#ffd866'",
        "color = #787700"="color='#ffd866'",
        "color=#ff0000"="color='#ff6b6b'",
        "color = #ff0000"="color='#ff6b6b'"
    )
    for(var/old in pairs)
        var/repval = pairs[old]
        t = replacetext(t, old, repval)
    return t

/proc/ui_build_styled_html(var/title, var/body_html)
    // Normalize contrast for older inline <font color> use
    body_html = _ui_remap_colors(body_html)
    var/html = "<html><head><title>[title]</title>"
    html += "<style>"
    html += "html,body{background:rgba(14,19,27,0.94);color:#d7f6ff;font-family:Verdana,Arial,Helvetica,sans-serif;font-size:9pt;margin:0;padding:0;}"
    html += ".wrap{padding:10px 12px;min-width:260px;max-width:720px;border:1px solid #3ad;border-radius:6px;box-shadow:0 0 14px rgba(58,173,255,0.25) inset, 0 0 12px rgba(8,18,28,0.6);}"
    html += ".hdr{font-size:10pt;color:#8fe3ff;letter-spacing:0.06em;margin-bottom:6px;text-transform:uppercase;}"
    html += ".accent{height:2px;background:linear-gradient(90deg,#3ad,transparent);margin:6px 0 8px 0;}"
    html += ".note{color:#9fd;opacity:0.85;font-size:8pt;}"
    html += ".content{line-height:1.35;}"
    html += "a{color:#b9ecff;text-decoration:none;} a:hover{text-decoration:underline;}"
    html += "table{border-collapse:collapse} td,th{border:1px solid #246;padding:2px 4px}"
    html += "</style>"
    html += "</head><body><div class='wrap'>"
    if(title)
        html += "<div class='hdr'>[sanitizeSafe(title, 64, 1, 1, 1)]</div><div class='accent'></div>"
    html += "<div class='content'>[body_html]</div>"
    html += "</div></body></html>"
    return html

// Convenience proc to open a styled browse window for a mob-like user
// - user: mob/client holder to send browse to
// - title: header text
// - body_html: the content
// - window_args: optional browse() args (e.g., "window=name;size=500x600")
/proc/ui_browse_styled(var/mob/user, var/title, var/body_html, var/window_args)
    if(!user)
        return
    var/page = ui_build_styled_html(title, body_html)
    user << browse(page, window_args)
