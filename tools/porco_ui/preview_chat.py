"""Preview the Porco/chat seam using production CSS and the actual chat scroller.

Run check.py with the same preview directory first, then this script.
"""
from pathlib import Path
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]
out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'tmp/porco-ui-check/preview'
out.mkdir(parents=True, exist_ok=True)
assets = (ROOT / 'code/modules/client/asset_cache.dm').read_text(encoding='utf-8')
needed = {
    'jquery.min.js', 'jquery.mousewheel.js', 'jquery.jscrollpane.min.js',
    'jquery.jscrollpane.css', 'browserOutput.css', 'chatbg.png', 'tchatshadow.png',
    'chatscrollbar-scrollup.png', 'chatscrollbar-scrolldown.png',
    'chatscroller-t.png', 'chatscroller-m.png', 'chatscroller-b.png',
}
for name, source in re.findall(r'"([^"\n]+)"\s*=\s*\x27([^\x27]+)\x27', assets):
    if name in needed:
        shutil.copyfile(ROOT / source, out / name)
messages = ''.join('<div class="entry"><span class="notice">Sample chat message %s</span></div>' % i for i in range(1, 40))
messages += '<div class="entry"><span class="notice">The lift arrives at the main level.</span></div><div class="entry">You hear footsteps in the corridor.</div><div class="entry"><a href="#sample">Open the communications log</a></div>'
(out / 'chat-seam.html').write_text('''<!doctype html><html><head><meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge"><title>Chat preview</title>
<link rel="stylesheet" href="browserOutput.css"><link rel="stylesheet" href="jquery.jscrollpane.css">
<script src="jquery.min.js"></script><script src="jquery.mousewheel.js"></script><script src="jquery.jscrollpane.min.js"></script>
</head><body><div class="scroll-pane-split"><div id="messages">''' + messages + '''</div></div><div class="topimg" aria-hidden="true"></div>
<script>var pane=$('.scroll-pane-split');pane.jScrollPane({showArrows:true,verticalDragMinHeight:24,stickToBottom:true,maintainPosition:true});pane.data('jsp').scrollToBottom();</script>
</body></html>''', encoding='utf-8')
(out / 'porco-chat-preview.html').write_text('''<!doctype html><html><head><meta charset="utf-8"><title>Porco and chat</title>
<style>body{margin:24px;min-width:541px;background:#171b1d;color:#c4d2d0;font:13px Verdana}h1{font-size:18px}p{color:#a1aeab}.panel{width:541px;background:#05060a}iframe{display:block;width:541px;border:0}.porco{height:315px;margin-bottom:1px}.chat{height:240px}</style>
</head><body><h1>Porco and chat</h1><p>Continuous shadow between the menu and message log.</p><div class="panel"><iframe class="porco" title="Porco menu" src="pig.html?preview=1"></iframe><iframe class="chat" title="Chat log" src="chat-seam.html"></iframe></div></body></html>''', encoding='utf-8')
print(out / 'porco-chat-preview.html')
