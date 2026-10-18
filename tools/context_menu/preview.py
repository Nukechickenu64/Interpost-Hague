"""Generate a small DM world that renders the production context-menu HTML.

Compile tmp/context-menu-preview/preview.dme and run its DMB with DreamDaemon.
Run again with --export DIRECTORY to package the resulting browser preview.
"""
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tmp/context-menu-preview'
OUT.mkdir(parents=True, exist_ok=True)
(OUT / '.gitignore').write_text('*\n')
source = (ROOT / 'code/_onclick/context_menu.dm').read_text(encoding='utf-8')

if '--export' not in sys.argv:
    tile, obj = source.split('/mob/proc/open_object_context_menu', 1)
    def renderer(text):
        start = text.index('\tvar/html = ')
        end = text.index('\tvar/browse_args = ', start)
        return text[start:end] + '\treturn html\n'
    program = '''#define FILE_DIR "../.."
/proc/sanitizeSafe(text, a, b, c, d)
    return html_encode(text)
/mob/proc/tilectx_bite_label()
    return "Bite (standard)"
/mob/proc/tile_preview()
    var/turf/floor = locate(1,1,1)
    floor.name = "Floor"
    var/obj/chair = new
    chair.name = "Chair"
    var/obj/item = new
    item.name = "Maintenance toolkit"
    var/mob/clicked = new
    clicked.name = "Vichor Marks"
    var/list/atoms_on_tile = list(floor, chair, item, clicked)
'''
    program += renderer(tile)
    program += '''/mob/proc/object_preview()
    var/obj/target = new
    target.name = "Maintenance toolkit"
    var/I = 1
    var/icon_w = 32
    var/icon_h = 32
    var/rsc_name = "Craft.png"
    var/can_give = 0
    var/can_bite = 0
    var/is_admin = 1
    var/turf/admin_jump_turf = locate(1,1,1)
    var/list/verbs_list = list(list("proc"="toggle", "label"="Open toolkit"), list("proc"="adjust", "label"="Adjust equipment"))
'''
    program += renderer(obj)
    program += source[source.index('/proc/tilectx_styles()'):]
    program += '''
/world
    maxx = 1
    maxy = 1
    maxz = 1
/world/New()
    var/mob/viewer = new
    fdel("tile.html")
    fdel("object.html")
    text2file(viewer.tile_preview(), "tile.html")
    text2file(viewer.object_preview(), "object.html")
    world.log << "Context menu preview rendered"
    shutdown()
'''
    (OUT / 'preview.dme').write_text(program.expandtabs(4), encoding='utf-8')
    print(OUT / 'preview.dme')
else:
    export = Path(sys.argv[sys.argv.index('--export') + 1])
    export.mkdir(parents=True, exist_ok=True)
    for name in ('tile', 'object'):
        html = (OUT / (name + '.html')).read_text(encoding='utf-8')
        html = re.sub(r'<script[^>]*>.*?</script>', '', html, flags=re.S)
        html = re.sub(r'href=([\'"])(.*?)\1', lambda m: 'href="' + ('object.html' if 'tilectx_obj=' in m[2] else 'tile.html' if 'tilectx_back=' in m[2] else '#') + '"', html)
        (export / (name + '.html')).write_text(html, encoding='utf-8')
    shutil.copyfile(ROOT / 'code/porco/html/Craft.png', export / 'Craft.png')
    (export / 'index.html').write_text('''<!doctype html><html><head><meta charset="utf-8"><title>Context menus</title>
<style>body{min-width:620px;margin:24px;background:#171b1d;color:#b9bdca;font:13px Verdana}h1{font-size:18px}p{color:#9099a9}.menus{display:flex;gap:24px;align-items:flex-start}figure{margin:0}figcaption{margin-bottom:10px;color:#bda58e}iframe{display:block;border:0}</style>
</head><body><h1>Context menus</h1><p>Compact lists with a selected-object marker and separate action controls.</p><div class="menus"><figure><figcaption>Tile selection</figcaption><iframe title="Tile selection" src="tile.html" width="246" height="230"></iframe></figure><figure><figcaption>Object actions</figcaption><iframe title="Object actions" src="object.html" width="266" height="450"></iframe></figure></div>
<script>var frames=document.querySelectorAll('iframe');for(var i=0;i<frames.length;i++){frames[i].onload=function(){var wrap=this.contentDocument.getElementById('wrap');this.width=wrap.offsetWidth;this.height=wrap.offsetHeight;};}</script></body></html>''', encoding='utf-8')
    print(export / 'index.html')
