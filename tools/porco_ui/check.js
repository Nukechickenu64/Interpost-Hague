/* Runs in the native BYOND browser, after DM has sent the real output callbacks. */
window.porcoCheck = function (stage) {
  var errors = [];
  function check(value, message) { if (!value) { errors.push(message); } }
  function node(id) { return document.getElementById(id); }
  function style(id) { return window.getComputedStyle(node(id)); }
  function report(next) {
    window.location.href = 'byond://?porco_check=' + next + '&errors=' + encodeURIComponent(errors.join('; '));
  }
  try {
    if (stage === 'human') {
      check(window.innerWidth === 541 && window.innerHeight === 315, 'Native panel dimensions');
      check(!node('device-close') && !node('device-resize'), 'No close or resize controls');
      check(style('device-frame').borderTopWidth === '3px', 'Shared bezel CSS delivered');
      check(style('stats-strip').display !== 'none' && node('st').innerHTML === '16', 'Initial stats callback');
      check(node('action-count').innerHTML === '24 ACTIONS', 'Action payload and separators');
      check(node('scrollbar_content').innerText.indexOf('$') < 0, 'No verb separators displayed');
      var pane = node('scrollbar_content');
      pane.scrollTop = 40;
      check(pane.scrollTop > 0, 'Native action scrolling');
      var content = pane.innerHTML;
      window.changel(content, '#Verb');
      check(pane.scrollTop === 40, 'Live refresh preserves scroll');
      var panels = ['stats-strip', 'action-panel', 'tabs-panel'];
      var glass = node('device-glass').getBoundingClientRect();
      for (var i = 0; i < panels.length; i++) {
        var box = node(panels[i]).getBoundingClientRect();
        check(box.left >= glass.left && box.right <= glass.right && box.top >= glass.top && box.bottom <= glass.bottom, panels[i] + ' fits glass');
      }
      check(node('action-panel').getBoundingClientRect().bottom < node('tabs-panel').getBoundingClientRect().top, 'Tabs never overlap actions');
      var icon = node('Craft').getBoundingClientRect();
      check(icon.width === 31 && icon.height === 31 && icon.top > 200, 'Backend absolute icon styles normalized');
      node('Craft').click();
      check(node('section-title').innerHTML === 'CRAFTING' && pane.innerText.indexOf('Craft Menu') >= 0, 'Craft tab switching');
      node('PorcoTab0').click();
      check(node('section-title').innerHTML === 'SPECIAL ROLE' && pane.innerText.indexOf('Role Action') >= 0, 'Custom role names and actions');
      node('options-link').click();
      check(node('section-title').innerHTML === 'OOC / OPTIONS', 'OOC tab');
      check(node('connection').className === 'online', 'Server handshake ready');
      node('Verb').click();
      check(pane.getElementsByTagName('a')[0].getAttribute('href') === 'byond://winset?command=PorcoTestAction', 'Real command href retained');
      report('human');
    } else if (stage === 'lobby') {
      check(style('stats-strip').display === 'none' && node('st').innerHTML === '--', 'Stats reset in lobby');
      check(style('role-divider').display === 'none', 'Empty role region collapses');
      node('options-link').click();
      window.change('timetostart', '27');
      node('Verb').click();
      check(node('timetostart').innerHTML === '27', 'Hidden lobby countdown updates');
      check(node('scrollbar_content').getElementsByTagName('br').length > 0, 'Lobby line breaks retained');
      report('lobby');
    } else if (stage === 'ghost') {
      node('DeadGhost').click();
      check(node('section-title').innerHTML === 'GHOST', 'Ghost tab');
      check(node('scrollbar_content').innerText.indexOf('Re-enter Corpse') >= 0, 'Ghost actions');
      check(style('stats-strip').display === 'none', 'Ghost has no human stats');
      window.InputMsg('Updated$Message');
      check(node('scrollbar_content').innerHTML.indexOf('Updated<br>Message') >= 0, 'Legacy InputMsg callback');
      window.change('st', '12');
      check(node('st').innerHTML === '12' && style('stats-strip').display !== 'none', 'Direct stat update');
      report('ghost');
    } else if (stage === 'action') {
      node('Verb').click();
      node('scrollbar_content').getElementsByTagName('a')[0].click();
    } else if (stage === 'who') {
      node('pig-link').click();
    }
  } catch (error) {
    errors.push(String(error.message || error));
    report(stage);
  }
};
