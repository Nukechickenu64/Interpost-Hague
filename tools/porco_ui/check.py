"""Generate a native Porco browser regression and a 541x315 browser preview.

python tools/porco_ui/check.py [preview directory]
Compile tmp/porco-ui-check/check.dme, run with DreamDaemon and connect a test
Dream Seeker. The isolated test world exits after completion or 30 seconds.
"""
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tmp/porco-ui-check'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / '.gitignore').write_text('*\n')
pig = (ROOT / 'code/porco/pig.dm').read_text(encoding='utf-8')
cache = (ROOT / 'code/modules/client/asset_cache.dm').read_text(encoding='utf-8')
assets = cache[cache.index('/datum/asset/pig\n'):cache.index('/datum/asset/group/goonchat\n')]
callbacks = pig[pig.index('/proc/generateVerbHtml'):pig.index('// The System Shock renderer')]
open_panel = pig[pig.index('/client/proc/lobbyPig()'):pig.index('/client/proc/init_pig()')]
skin = '''window "outputwindow"
    elem "outputwindow"
        type = MAIN
        size = 541x315
        is-default = true
    elem "browser"
        type = BROWSER
        pos = 0,0
        size = 541x315
        border = sunken
'''
(OUT / 'check.dmf').write_text(skin)
html = (ROOT / 'code/porco/html/pig.html').read_text(encoding='utf-8')
(OUT / 'check.html').write_text(html.replace('<script src="pig.js">', '<script src="porco-check.js"></script><script src="pig.js">'), encoding='utf-8')
# Exercise the production opener with the same document plus test assertions.
open_panel = open_panel.replace("'code/porco/html/pig.html'", "'tmp/porco-ui-check/check.html'")
harness = r'''
#define TRUE 1
/datum/asset/simple
    var/verify
    var/list/assets
/world
    fps = 10
/world/New()
    spawn(300)
        world.log << "PORCO NATIVE: FAIL (timeout)"
        shutdown()
/client
    var/failures = 0
/client/New()
    . = ..()
    spawn(5)
        var/datum/asset/pig/resources = new
        for(var/name in resources.assets)
            src << browse_rsc(resources.assets[name], name)
        src << browse_rsc('tools/porco_ui/check.js', "porco-check.js")
        lobbyPig()
/client/proc/tab(id, icon, title = "")
    return "<a href='#' title='[title]' style='position:absolute;margin-left:45px'><div id='[id]' class='button' style='background-image:url([icon]);position:relative;top:-132px;width:32px;height:32px'></div></a>"
/client/proc/run_check(stage)
    src << output(list2params(list(stage)), "outputwindow.browser:porcoCheck")
/client/verb/ready()
    set name = "doneRsc"
    set hidden = 1
    addbutton(tab("Verb", "Heart.png") + tab("Emotes", "Emotes.png") + tab("Craft", "Craft.png"), "#dynamicpanel")
    addbutton(tab("PorcoTab0", "Villain.png", "Special Role"), "#dynamicpanel2")
    changebuttoncontent("#note", "<span>ST: <span id='st'>16</span>$HT: <span id='ht'>10</span>$IN: <span id='int'>14</span>$DX: <span id='dx'>9</span></span>")
    var/list/actions = list()
    for(var/i = 1 to 24)
        actions += list(list("PorcoTestAction", "Action [i]"))
    changebuttoncontent("#Verb", "<span class='segment1'>[generateVerbList(actions)]</span>")
    changebuttoncontent("#Craft", "<span class='segment1'>[generateVerbList(list(list("CraftMenu", "Craft Menu")))]</span>")
    changebuttoncontent("#options", "<span class='segment1'>[generateVerbList(list(list("OOC", "OOC")))]</span>")
    changebuttoncontent("#PorcoTab0", "<span class='segment1'>[generateVerbList(list(list("RoleAction", "Role Action")))]</span>")
    spawn(10)
        run_check("human")
/client/Topic(href, list/href_list)
    var/stage = href_list["porco_check"]
    if(!stage)
        return
    if(href_list["errors"])
        failures++
        world.log << "FAIL [stage]: [href_list["errors"]]"
    else
        world.log << "PASS [stage]"
    switch(stage)
        if("human")
            run_check("action")
        if("lobby")
            addbutton(tab("Verb", "Heart.png") + tab("DeadGhost", "Dead.png"), "#dynamicpanel")
            changebuttoncontent("#DeadGhost", "<span class='segment1'>[generateVerbList(list(list("ReenterCorpse", "Re-enter Corpse")))]</span>")
            run_check("ghost")
        if("ghost")
            if(winget(src, "outputwindow.browser", "border") != "none")
                failures++
                world.log << "FAIL native browser border"
            world.log << "PORCO NATIVE: [failures ? "FAIL" : "PASS"]"
            shutdown()
/client/verb/PorcoTestAction()
    set hidden = 1
    world.log << "PASS action command dispatched"
    run_check("who")
/client/verb/Who()
    world.log << "PASS WHO command dispatched"
    addbutton("", "#dynamicpanel2")
    addbutton(tab("Verb", "Heart.png"), "#dynamicpanel")
    changebuttoncontent("#note", "")
    changebuttoncontent("#Verb", "<span style='color:#0e3b0e'>Time to Start: <span id='timetostart'>30</span>$Ready</span>")
    run_check("lobby")
'''
# Resources are compiled from their production paths, not copied stand-ins.
dme = '#include "check.dmf"\n' + harness + assets + callbacks + open_panel
dme = '#define FILE_DIR "../.."\n' + dme
(OUT / 'check.dme').write_text(dme, encoding='utf-8')

preview = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT / 'preview'
preview.mkdir(parents=True, exist_ok=True)
for name, source in re.findall(r'"([^"\n]+)"\s*=\s*\x27([^\x27]+)\x27', assets):
    if name in ['pig.html', 'pig.js', 'style.css', 'device-ui.css', 'Heart.png', 'Emotes.png', 'Craft.png', 'Dead.png', 'Thanati.png', 'Chrome.png', 'Villain.png']:
        shutil.copyfile(ROOT / source, preview / name)
(preview / 'porco-preview.html').write_text('''<!doctype html><html><head><meta charset="utf-8"><title>Porco menu preview</title>
<style>body{margin:24px;background:#171b1d;color:#c4d2d0;font:13px Verdana}h1{font-size:18px}iframe{display:block;border:0;width:541px;height:315px}p{color:#a1aeab}</style></head>
<body><h1>Porco menu</h1><p>541 × 315 in-game panel · sample actions and stats</p><iframe title="Porco panel" src="pig.html?preview=1"></iframe></body></html>''', encoding='utf-8')
print(OUT / 'check.dme')
print(preview / 'porco-preview.html')
