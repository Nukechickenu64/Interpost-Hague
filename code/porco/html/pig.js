/* PORCO / FUNCTIONAL. ES5 for BYOND browser; retains pig.dm's output entry points. */
(function () {
  'use strict';
  var data = {};
  var active = 'Verb';
  var pane = document.getElementById('scrollbar_content');
  var title = document.getElementById('section-title');
  var count = document.getElementById('action-count');
  var hint = document.getElementById('tab-hint');
  var isPreview = window.PORCO_PREVIEW === true || /(?:\?|&)preview=1(?:&|$)/.test(window.location.search);
  var modeNames = {
    Verb:'ACTIONS', Emotes:'EMOTES', Craft:'CRAFTING', DeadGhost:'GHOST', Dead:'DEATH',
    options:'OOC / OPTIONS', Thanati:'THANATI', Integralist:'INTEGRALIST',
    Xenophage:'XENOPHAGE', They:'THEY', Religion:'RELIGION'
  };
  if (isPreview) { document.body.className += ' preview'; }
  document.body.className += ' no-roles';

  function el(id) { return document.getElementById(id); }
  function classFlag(flag, enabled) {
    document.body.className = document.body.className.replace(new RegExp('(?:^|\\s)' + flag + '(?=\\s|$)', 'g'), '');
    if (enabled) { document.body.className += ' ' + flag; }
  }
  function byondCommand(command) {
    if (!isPreview) { window.location.href = 'byond://winset?command=' + encodeURIComponent(command); }
  }
  window.byondCommand = byondCommand;
  function cancel(e) {
    e = e || window.event;
    if (e) { if (e.preventDefault) { e.preventDefault(); } e.returnValue=false; e.cancelBubble=true; }
    return false;
  }
  function idOf(selector) { return String(selector || '').replace(/^#/, ''); }
  function displayName(key) {
    if (modeNames[key]) { return modeNames[key]; }
    var icon = el(key);
    var parent = icon && icon.parentNode;
    if (parent && parent.getAttribute && parent.getAttribute('title')) { return parent.getAttribute('title').toUpperCase(); }
    return String(key || 'ACTIONS').replace(/([a-z])([A-Z])/g,'$1 $2').toUpperCase();
  }
  function serverReady() {
    el('connection').className = 'online';
    el('connection').innerHTML = '<i></i>READY';
  }
  function selected(key) {
    var links = document.querySelectorAll('#dynamicpanel > a, #dynamicpanel2 > a, #options-link');
    for (var i = 0; i < links.length; i++) {
      links[i].className = String(links[i].className || '').replace(/\sselected\b/g,'');
    }
    var item=el(key), parent=item && item.parentNode;
    if (parent && parent.tagName && parent.tagName.toLowerCase()==='a') { parent.className += ' selected'; }
    if (key==='options') { el('options-link').className += ' selected'; }
  }
  function emptyState() { return '<div class="empty-state">No actions available for this tab.</div>'; }
  function normalize(html) {
    if (!html) { return emptyState(); }
    var text=String(html);
    // DM's generateVerbList inserts '$' after every <a>. In a grid those are
    // separators, not visible line breaks; keep '$' breaks in lobby text.
    text=text.replace(/(<span\b[^>]*class=['"][^'"]*segment[12][^'"]*['"][^>]*>)([\s\S]*?)(<\/span>)/gi,
      function (_, start, body, end) { return start+body.replace(/\$/g,'')+end; });
    return text.replace(/\$/g,'<br>');
  }
  function countActions() {
    var all=pane.getElementsByTagName('a'), total=0;
    for (var i=0;i<all.length;i++) { if (String(all[i].className || '').indexOf('verb') >= 0) { total++; } }
    count.innerHTML=total ? (total+' ACTION'+(total===1?'':'S')) : '';
  }
  function show(key, keepScroll) {
    var y=keepScroll ? pane.scrollTop : 0;
    active=key;
    title.innerHTML=displayName(key);
    hint.innerHTML=displayName(key);
    var html=normalize(data[key]);
    if (pane.innerHTML !== html) { pane.innerHTML=html; }
    pane.scrollTop=y;
    countActions();
    selected(key);
  }
  function updateStatsFromNote(html) {
    var container=document.createElement('div');
    container.innerHTML=String(html || '');
    var ids=['st','ht','int','dx'];
    var haveData=false;
    for (var i=0;i<ids.length;i++) {
      var spans=container.getElementsByTagName('span');
      for (var j=0;j<spans.length;j++) {
        if (spans[j].id === ids[i]) {
          el(ids[i]).innerHTML=spans[j].innerHTML;
          haveData=true;
          break;
        }
      }
    }
    classFlag('has-stats',haveData);
    if (!haveData) {
      for (var k=0;k<ids.length;k++) { el(ids[k]).innerHTML='--'; }
    }
  }
  function isStat(id) { return id==='st'||id==='ht'||id==='int'||id==='dx'; }
  function contains(root,node) {
    while (node && node!==document) { if (node===root) { return true; } node=node.parentNode; }
    return false;
  }
  function iconButton(node) {
    while (node && node !== document) {
      if (node.id && String(node.className || '').indexOf('button') !== -1 &&
          (contains(el('dynamicpanel'), node) || contains(el('dynamicpanel2'), node))) { return node; }
      if (node.tagName && node.tagName.toLowerCase()==='a' &&
          (contains(el('dynamicpanel'),node) || contains(el('dynamicpanel2'),node))) {
        var elements=node.getElementsByTagName('div');
        if (elements.length && elements[0].id) { return elements[0]; }
      }
      node=node.parentNode;
    }
    return null;
  }
  function updateTabIcons(id) {
    var root=el(id), links=root.getElementsByTagName('a');
    for (var i=0;i<links.length;i++) {
      var child=links[i].getElementsByTagName('div')[0];
      if (!links[i].title && child && child.id) { links[i].title=displayName(child.id); }
      if (child && child.id) { links[i].setAttribute('aria-label',links[i].title); }
      links[i].onmouseover=function(){ hint.innerHTML=String(this.title || 'ACTIONS').toUpperCase(); };
      links[i].onmouseout=function(){ hint.innerHTML=displayName(active); };
    }
    classFlag('no-roles',el('dynamicpanel2').getElementsByTagName('a').length === 0);
  }
  function fallbackIfMissing() {
    if (active!=='options' && active!=='Verb' && !el(active)) { show('Verb',false); }
  }
  // BYOND outputwindow.browser:InputMsg
  window.InputMsg = function (html) {
    data[active] = String(html || '');
    show(active,false);
  };
  // BYOND outputwindow.browser:addel
  window.addel = function (html, selector) {
    var id=idOf(selector), root=el(id);
    if (id!=='dynamicpanel' && id!=='dynamicpanel2') { return; }
    if (!root) { return; }
    if (root.innerHTML !== String(html || '')) { root.innerHTML=html || ''; }
    updateTabIcons(id);
    fallbackIfMissing();
    selected(active);
    serverReady();
  };
  // BYOND outputwindow.browser:changel
  window.changel = function (html, selector) {
    var id=idOf(selector), value=String(html || '');
    if (id==='note') { updateStatsFromNote(value); }
    if (data[id] !== value) {
      data[id] = value;
      if (id===active) { show(id,true); }
    }
    serverReady();
  };
  // BYOND outputwindow.browser:change
  window.change = function (id, value) {
    id=idOf(id);
    var v=String(value == null ? '' : value);
    var target=el(id);
    if (target) { target.innerHTML=v; }
    if (isStat(id)) { classFlag('has-stats',true); }
    // Update hidden tab HTML, too (notably lobby countdown's #timetostart).
    for (var key in data) {
      if (!data.hasOwnProperty(key) || data[key].indexOf('id=')<0 || data[key].indexOf(id)<0) { continue; }
      var tmp=document.createElement('div');
      tmp.innerHTML=data[key];
      var items=tmp.getElementsByTagName('span');
      var changed=false;
      for (var i=0;i<items.length;i++) {
        if (items[i].id===id) { items[i].innerHTML=v;changed=true;break; }
      }
      if (changed) { data[key]=tmp.innerHTML; }
    }
    serverReady();
  };
  function switchTab(e) {
    e=e||window.event;
    var btn=iconButton(e.target||e.srcElement);
    if (btn) { show(btn.id,false);return cancel(e); }
    return true;
  }
  el('dynamicpanel').onclick=switchTab;
  el('dynamicpanel2').onclick=switchTab;
  el('options-link').onclick=function(e){show('options',false);return cancel(e);};
  function scrollTabs(e){
    e=e||window.event;
    this.scrollLeft+=(e.wheelDelta||0)<0 ? 35:-35;
    return cancel(e);
  }
  el('dynamicpanel').onmousewheel=scrollTabs;
  el('dynamicpanel2').onmousewheel=scrollTabs;
  if (isPreview) {
    el('pig-link').onclick=function(e){return cancel(e);};
    var actions=['Disguise Voice','Dance','Pee','Look Up','Move Upwards','Show Goals','Memories','Add Memories','Pray','Poo','Look Down','Move Down'];
    var emotes=['Slap','Nod','Hug','Bow','Scream','Whimper','Laugh','Sigh','Cough','Yawn','Wink','Grumble','Charge','Cry','Smile'];
    function mockActions(a) {
      var result='<span class="segment1">';
      for (var i=0;i<a.length;i++) { result+='<a class="verb'+(i%2?' dim':'')+'" href="#">'+a[i]+'</a>'; }
      return result+'</span>';
    }
    window.addel('<a href="#"><div class="button" id="Verb" style="background-image:url(Heart.png)"></div></a><a href="#"><div class="button" id="Emotes" style="background-image:url(Emotes.png)"></div></a><a href="#"><div class="button" id="Craft" style="background-image:url(Craft.png)"></div></a><a href="#"><div class="button" id="DeadGhost" style="background-image:url(Dead.png)"></div></a>', '#dynamicpanel');
    window.addel('<a href="#" title="Thanati"><div class="button" id="Thanati" style="background-image:url(Thanati.png)"></div></a><a href="#" title="Integralist"><div class="button" id="Integralist" style="background-image:url(Chrome.png)"></div></a>', '#dynamicpanel2');
    window.changel(mockActions(actions),'#Verb');
    window.changel(mockActions(emotes),'#Emotes');
    window.changel(mockActions(['Craft Menu']),'#Craft');
    window.changel(mockActions(['Respawn','Follow','Teleport','Toggle Ghost Vision','Re-enter Corpse']),'#DeadGhost');
    window.changel(mockActions(['Praise Your God','Create Shrine']),'#Thanati');
    window.changel(mockActions(['Invoke','Communicate']),'#Integralist');
    window.changel(mockActions(['OOC','Admin Help','Show Achievements']),'#options');
    window.change('st','10');window.change('ht','10');window.change('int','14');window.change('dx','9');
    pane.onclick=function(e){
      e=e||window.event;
      var t=e.target||e.srcElement;
      if (t && t.tagName && t.tagName.toLowerCase()==='a') {return cancel(e);}
    };
  } else {
    byondCommand('doneRsc');
  }
  show(active,false);
})();
