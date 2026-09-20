// Shared styled HTML wrapper for browser windows, matching the diegetic context menu look

// Build a styled HTML page with a title and provided body content.
// - title: small uppercase header shown at the top
// - body_html: inner HTML for the page body (already sanitized/encoded by caller if needed)
// Returns a complete HTML document string ready for browse()
/proc/_ui_remap_colors(var/t as text)
    if(!t) return ""
    // Map legacy low-contrast colors to bright theme-friendly ones
    var/list/pairs = list(
        "color='black'"="color='#c8c1b3'",
        "color=\"black\""="color='#c8c1b3'",
        "color = 'black'"="color='#c8c1b3'",
        "color = \"black\""="color='#c8c1b3'",
        "color='blue'"="color='#d7b46a'",
        "color=\"blue\""="color='#d7b46a'",
        "color='maroon'"="color='#e0836f'",
        "color=\"maroon\""="color='#e0836f'",
        "color='red'"="color='#e0836f'",
        "color=\"red\""="color='#e0836f'",
        "color='green'"="color='#9fd88f'",
        "color=\"green\""="color='#9fd88f'",
        "color='orange'"="color='#f0cf84'",
        "color=\"orange\""="color='#f0cf84'",
        "color='grey'"="color='#8f8b82'",
        "color=\"grey\""="color='#8f8b82'",
        "color='gray'"="color='#8f8b82'",
        "color=\"gray\""="color='#8f8b82'",
        // Common hex usages in legacy UIs
        "color=#18743e"="color='#9fd88f'",
        "color = #18743e"="color='#9fd88f'",
        "color=#990000"="color='#e0836f'",
        "color = #990000"="color='#e0836f'",
        "color=#787700"="color='#f0cf84'",
        "color = #787700"="color='#f0cf84'",
        "color=#ff0000"="color='#e0836f'",
        "color = #ff0000"="color='#e0836f'"
    )
    for(var/old in pairs)
        var/repval = pairs[old]
        t = replacetext(t, old, repval)
    return t

/proc/ui_build_styled_html(var/title, var/body_html, var/paper_style = FALSE)
    if(!paper_style)
        // Normalize contrast for older inline <font color> use
        body_html = _ui_remap_colors(body_html)
    var/html = "<!DOCTYPE html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'/><meta charset='utf-8'/><title>[title]</title>"
    html += "<style>"
    if(paper_style)
        html += "html,body{background:#fffdf5;color:#171717;font-family:Verdana,Arial,Helvetica,sans-serif;font-size:10pt;margin:0;padding:0;}"
        html += ".wrap{padding:14px 16px;min-width:260px;max-width:720px;border:1px solid #c9c2ae;border-radius:2px;box-shadow:0 1px 5px rgba(50,40,20,0.18);}"
        html += ".hdr{font-size:10pt;color:#3b3428;letter-spacing:0.06em;margin-bottom:6px;text-transform:uppercase;}"
        html += ".accent{height:1px;background:#c9c2ae;margin:6px 0 10px 0;}"
        html += ".note{color:#514b40;font-size:8pt;}"
        html += "a{color:#164f82;text-decoration:underline;} a:hover{color:#0b3152;}"
        html += "table{border-collapse:collapse} td,th{border:1px solid #b8b09e;padding:2px 4px}"
    else
        // Matches the orange/black theme used by nano UI (nano/css/shared.css) and html_interface.css
        html += "html,body{background:#090a0b;color:#c8c1b3;font-family:Verdana,Arial,Helvetica,sans-serif;font-size:9pt;margin:0;padding:0;}"
        html += ".wrap{padding:10px 12px;min-width:260px;max-width:720px;border:1px solid #4a4035;border-radius:2px;box-shadow:0 0 14px rgba(139,47,34,0.25) inset, 0 0 12px rgba(0,0,0,0.6);background:#11100e;}"
        html += ".hdr{font-size:10pt;color:#f0cf84;letter-spacing:0.06em;margin-bottom:6px;text-transform:uppercase;}"
        html += ".accent{height:2px;background:linear-gradient(90deg,#5d241b,transparent);margin:6px 0 8px 0;}"
        html += ".note{color:#8f8b82;opacity:0.9;font-size:8pt;}"
        html += "a{color:#d7b46a;text-decoration:none;} a:hover{color:#f0cf84;background:#231816;}"
        html += "table{border-collapse:collapse} td,th{border:1px solid #4a4035;padding:2px 4px}"
    html += ".content{line-height:1.35;}"
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
