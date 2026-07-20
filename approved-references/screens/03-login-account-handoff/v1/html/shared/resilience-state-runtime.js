(function () {
  'use strict';

  var params = new URLSearchParams(location.search);
  var scenario = params.get('microScenario') || '';
  if (!scenario) return;

  var targetLabel = normalize(params.get('microTarget') || '');
  var bypassed = new WeakSet();
  var screenMatch = location.pathname.match(/\/(\d{2,3})-[^/]+[.]html$/);
  var screen = screenMatch ? String(parseInt(screenMatch[1], 10)) : '0';
  var route = readRouteContract();
  var routeName = humanize(route.routeState || route.routeId || document.title || 'this screen');
  var moduleName = humanize(route.productionModule || 'MoolSocial');
  var surface = Array.prototype.slice.call(document.querySelectorAll('.production-phone,.phone-frame,.phone-shell,.device,.phone,.app')).find(function (candidate) {
    var rect = candidate.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0 && rect.bottom > 0 && rect.top < innerHeight && rect.right > 0 && rect.left < innerWidth;
  }) || document.body;

  ensureStyles();
  surface.classList.add('mool-resilience-surface');

  function normalize(value) {
    return String(value || '').replace(/\s+/g, ' ').trim();
  }

  function humanize(value) {
    return normalize(String(value || '').replace(/[._/-]+/g, ' ')).replace(/\b\w/g, function (letter) {
      return letter.toUpperCase();
    });
  }

  function readRouteContract() {
    var node = document.getElementById('productionRouteContract');
    if (!node) return {};
    try {
      return JSON.parse(node.textContent || '{}');
    } catch (error) {
      return {};
    }
  }

  function ensureStyles() {
    if (document.getElementById('mool-resilience-styles')) return;
    var style = document.createElement('style');
    style.id = 'mool-resilience-styles';
    style.textContent = [
      '.mool-resilience-surface{position:relative!important}',
      '.mool-resilience-panel{position:fixed;z-index:2147483647;display:grid;align-content:start;overflow:auto;overscroll-behavior:contain;box-sizing:border-box;padding:24px;background:#f7f8ff;color:#101338;font-family:Inter,Arial,sans-serif}',
      '.mool-resilience-card{width:min(100%,420px);margin:0 auto;border:1px solid #d9dcef;border-radius:16px;background:#fff;padding:22px;box-sizing:border-box;box-shadow:0 18px 50px rgba(16,19,56,.18)}',
      '.mool-resilience-kicker{margin:0 0 7px;color:#5d6388;font-size:11px;font-weight:900;letter-spacing:.08em;text-transform:uppercase}',
      '.mool-resilience-card h2{margin:0;color:#101338;font-size:24px;line-height:1.15}',
      '.mool-resilience-copy{margin:10px 0 0;color:#505777;font-size:14px;line-height:1.5}',
      '.mool-resilience-context{margin:14px 0 0;padding:10px 12px;border-left:4px solid #ff8a00;background:#fff8ea;color:#694000;font-size:12px}',
      '.mool-resilience-actions{display:grid;gap:9px;margin-top:18px}',
      '.mool-resilience-actions button,.mool-resilience-actions a{min-height:46px;display:grid;place-items:center;border-radius:10px;padding:10px 14px;font:800 14px/1.2 Inter,Arial,sans-serif;text-decoration:none;cursor:pointer}',
      '.mool-resilience-primary{border:0;background:#1013a8;color:#fff}',
      '.mool-resilience-secondary{border:1px solid #1013a8;background:#fff;color:#1013a8}',
      '.mool-resilience-spinner{width:34px;height:34px;margin:0 0 15px;border:4px solid #e2e4ff;border-top-color:#1013a8;border-radius:50%;animation:mool-resilience-spin .75s linear infinite}',
      '.mool-resilience-status{position:fixed;z-index:2147483647;left:50%;bottom:90px;transform:translateX(-50%);width:min(calc(100% - 28px),420px);border-radius:10px;background:#101338;color:#fff;padding:12px 14px;font:700 13px/1.4 Inter,Arial,sans-serif;box-shadow:0 10px 30px rgba(16,19,56,.25)}',
      '.mool-field-error{display:block;margin:5px 0 0;color:#a32626;font:700 12px/1.35 Inter,Arial,sans-serif}',
      '[aria-invalid="true"]{outline:2px solid #c33!important;outline-offset:2px}',
      '@keyframes mool-resilience-spin{to{transform:rotate(360deg)}}'
    ].join('');
    document.head.appendChild(style);
  }

  function controlLabel(element) {
    return normalize(
      element.getAttribute('aria-label') ||
      element.getAttribute('title') ||
      element.getAttribute('placeholder') ||
      element.innerText ||
      element.textContent ||
      element.value ||
      element.name
    );
  }

  function compactLabel(value) {
    var label = normalize(value);
    return label.length > 88 ? label.slice(0, 85).trim() + '...' : label;
  }

  function matchesTarget(element) {
    return element.getAttribute('data-mool-micro-target') === 'true' ||
      !targetLabel || normalize(controlLabel(element)).toLowerCase() === targetLabel.toLowerCase();
  }

  function removePanel() {
    var existing = document.querySelector('[data-mool-resilience="panel"]');
    if (existing) existing.remove();
  }

  function showStatus(message) {
    var existing = document.querySelector('[data-mool-resilience="status"]');
    if (existing) existing.remove();
    var status = document.createElement('div');
    status.className = 'mool-resilience-status';
    status.setAttribute('role', 'status');
    status.setAttribute('aria-live', 'polite');
    status.setAttribute('data-mool-resilience', 'status');
    status.textContent = message;
    document.body.appendChild(status);
  }

  function actionButton(label, kind, handler) {
    var button = document.createElement('button');
    button.type = 'button';
    button.className = kind === 'primary' ? 'mool-resilience-primary' : 'mool-resilience-secondary';
    button.textContent = label;
    button.addEventListener('click', handler);
    return button;
  }

  function renderPanel(options) {
    removePanel();
    var panel = document.createElement('section');
    panel.className = 'mool-resilience-panel';
    panel.setAttribute('data-mool-resilience', 'panel');
    panel.setAttribute('data-scenario', scenario);
    panel.setAttribute('role', options.alert ? 'alertdialog' : 'region');
    panel.setAttribute('aria-label', options.title);
    if (options.busy) panel.setAttribute('aria-busy', 'true');

    var card = document.createElement('div');
    card.className = 'mool-resilience-card';
    if (options.busy) {
      var spinner = document.createElement('div');
      spinner.className = 'mool-resilience-spinner';
      spinner.setAttribute('aria-hidden', 'true');
      card.appendChild(spinner);
    }
    var kicker = document.createElement('p');
    kicker.className = 'mool-resilience-kicker';
    kicker.textContent = moduleName + ' · ' + routeName;
    var title = document.createElement('h2');
    title.textContent = options.title;
    var copy = document.createElement('p');
    copy.className = 'mool-resilience-copy';
    copy.textContent = options.copy;
    card.append(kicker, title, copy);
    if (options.context) {
      var context = document.createElement('p');
      context.className = 'mool-resilience-context';
      context.textContent = options.context;
      card.appendChild(context);
    }
    if (options.actions && options.actions.length) {
      var actions = document.createElement('div');
      actions.className = 'mool-resilience-actions';
      options.actions.forEach(function (item) {
        actions.appendChild(actionButton(item.label, item.kind, item.run));
      });
      card.appendChild(actions);
    }
    panel.appendChild(card);
    document.body.appendChild(panel);
    fitPanel(panel);
    return panel;
  }

  function fitPanel(panel) {
    if (!panel || !panel.isConnected) return;
    var rect = surface.getBoundingClientRect();
    var left = Math.max(0, rect.left);
    var right = Math.min(innerWidth, rect.right);
    var top = Math.max(0, rect.top);
    var bottom = Math.min(innerHeight, rect.bottom);
    panel.style.left = left + 'px';
    panel.style.top = top + 'px';
    panel.style.width = Math.max(1, right - left) + 'px';
    panel.style.height = Math.max(1, bottom - top) + 'px';
  }

  window.addEventListener('resize', function () {
    fitPanel(document.querySelector('[data-mool-resilience="panel"]'));
  });
  window.addEventListener('scroll', function () {
    fitPanel(document.querySelector('[data-mool-resilience="panel"]'));
  }, true);

  function retryRoute(message) {
    removePanel();
    showStatus(message + ' ' + routeName + ' is ready.');
  }

  function signInRoute() {
    var returnPath = location.pathname.split('/').pop() || '';
    location.href = '03-login-account-handoff.html?return=' + encodeURIComponent(returnPath);
  }

  function routeScenario() {
    if (scenario === 'route-loading') {
      renderPanel({
        title: 'Loading ' + routeName,
        copy: 'Checking the latest ' + moduleName.toLowerCase() + ' information and restoring your place.',
        context: 'Your current task and selections are retained.',
        busy: true
      });
      setTimeout(function () {
        removePanel();
        showStatus(routeName + ' is ready.');
      }, 1800);
      return true;
    }
    if (scenario === 'route-empty') {
      renderPanel({
        title: 'Nothing to show here yet',
        copy: 'There are no current items for ' + routeName + '. You can refresh now or return without losing your place.',
        context: 'Filters and account context remain unchanged.',
        actions: [
          { label: 'Refresh', kind: 'primary', run: function () { retryRoute('Refreshed.'); } },
          { label: 'Return', kind: 'secondary', run: function () { retryRoute('Returned to the current screen.'); } }
        ]
      });
      return true;
    }
    if (scenario === 'route-offline') {
      renderPanel({
        title: 'You are offline',
        copy: routeName + ' could not refresh. Reconnect and retry; your current task has not been submitted twice.',
        context: 'Entered details and selected options remain on this device.',
        alert: true,
        actions: [
          { label: 'Retry connection', kind: 'primary', run: function () { retryRoute('Connection restored.'); } },
          { label: 'Cancel', kind: 'secondary', run: function () { retryRoute('Retry cancelled.'); } }
        ]
      });
      return true;
    }
    if (scenario === 'route-unauthorized') {
      renderPanel({
        title: 'Sign in to continue',
        copy: 'Your secure session for ' + routeName + ' has expired. Sign in again to return to this exact screen.',
        context: 'No order, payment, proof or draft has been submitted again.',
        alert: true,
        actions: [
          { label: 'Sign in again', kind: 'primary', run: signInRoute },
          { label: 'Return', kind: 'secondary', run: function () { retryRoute('Stayed on the current screen.'); } }
        ]
      });
      return true;
    }
    if (scenario === 'route-error') {
      renderPanel({
        title: 'Could not load ' + routeName,
        copy: 'MoolSocial could not complete this refresh. Try again or return to the current screen.',
        context: 'Your task state is retained and no duplicate action was created.',
        alert: true,
        actions: [
          { label: 'Try again', kind: 'primary', run: function () { retryRoute('Retry completed.'); } },
          { label: 'Cancel', kind: 'secondary', run: function () { retryRoute('Retry cancelled.'); } }
        ]
      });
      return true;
    }
    return false;
  }

  function replayOriginal(element, message) {
    removePanel();
    showStatus(message);
    bypassed.add(element);
    setTimeout(function () {
      element.click();
    }, 0);
  }

  function stableReference(label) {
    var hash = 0;
    for (var index = 0; index < label.length; index += 1) hash = (hash * 31 + label.charCodeAt(index)) >>> 0;
    return 'C2-' + String(screen).padStart(3, '0') + '-' + String(hash % 100000).padStart(5, '0');
  }

  function showActionInterruption(element, label, kind) {
    var offline = kind === 'action-offline';
    var displayLabel = compactLabel(label);
    renderPanel({
      title: offline ? 'Connection lost before ' + displayLabel : 'Could not ' + displayLabel,
      copy: offline
        ? 'Reconnect and retry this exact action. Your entries and selections are still here.'
        : 'The action did not complete. You can retry it now or cancel without losing your place.',
      context: 'MoolSocial will submit this action only once.',
      alert: true,
      actions: [
        {
          label: offline ? 'Retry connection' : 'Try again',
          kind: 'primary',
          run: function () {
            replayOriginal(element, (offline ? 'Connection restored. ' : 'Retry started. ') + displayLabel + ' is continuing.');
          }
        },
        {
          label: 'Cancel',
          kind: 'secondary',
          run: function () {
            removePanel();
            showStatus(displayLabel + ' was not submitted. Your current screen state is unchanged.');
          }
        }
      ]
    });
  }

  function showPermissionDenied(label) {
    var displayLabel = compactLabel(label);
    renderPanel({
      title: 'Permission not granted',
      copy: displayLabel + ' needs a device permission that is currently off. You remain in the same task.',
      context: 'Choose device settings, continue with a manual option, or cancel.',
      alert: true,
      actions: [
        {
          label: 'Open device settings',
          kind: 'primary',
          run: function () {
            removePanel();
            showStatus('Device settings handoff is ready. Return to retry ' + displayLabel + '.');
          }
        },
        {
          label: 'Continue without permission',
          kind: 'secondary',
          run: function () {
            removePanel();
            showStatus('Manual fallback selected for ' + displayLabel + '. Your task remains open.');
          }
        },
        {
          label: 'Cancel',
          kind: 'secondary',
          run: function () {
            removePanel();
            showStatus(displayLabel + ' cancelled. No permission or task state changed.');
          }
        }
      ]
    });
  }

  function showDuplicate(element, label) {
    var reference = stableReference(label);
    var displayLabel = compactLabel(label);
    renderPanel({
      title: 'Duplicate stopped',
      copy: 'Original request ' + reference + ' remains active. No second order, payment, message or submission was created.',
      context: displayLabel + ' can continue from its one retained result.',
      actions: [
        {
          label: 'View result',
          kind: 'primary',
          run: function () {
            replayOriginal(element, 'Original result ' + reference + ' is open.');
          }
        },
        { label: 'Close', kind: 'secondary', run: removePanel }
      ]
    });
  }

  function clearFieldError(element) {
    element.removeAttribute('aria-invalid');
    var error = element.parentElement && element.parentElement.querySelector('[data-mool-resilience="field-error"]');
    if (error) error.remove();
  }

  function showFieldError(element, message) {
    clearFieldError(element);
    var id = element.id || ('mool-field-' + screen + '-' + Math.random().toString(16).slice(2));
    element.id = id;
    element.setAttribute('aria-invalid', 'true');
    var error = document.createElement('span');
    error.id = id + '-error';
    error.className = 'mool-field-error';
    error.setAttribute('role', 'alert');
    error.setAttribute('data-mool-resilience', 'field-error');
    error.setAttribute('data-for', id);
    error.textContent = message;
    element.setAttribute('aria-describedby', error.id);
    element.insertAdjacentElement('afterend', error);
  }

  function fieldValue(element) {
    return normalize(element.isContentEditable ? element.textContent : element.value);
  }

  function validField(element) {
    var value = fieldValue(element);
    var type = String(element.type || '').toLowerCase();
    var inputMode = String(element.getAttribute('inputmode') || '').toLowerCase();
    if (!value) return !element.required && scenario !== 'empty-input';
    if (type === 'email' && !/^[^@\s]+@[^@\s]+[.][^@\s]+$/.test(value)) return false;
    if ((type === 'tel' || inputMode === 'numeric') && !/^\d+$/.test(value)) return false;
    if (type === 'number') {
      var number = Number(value);
      if (!Number.isFinite(number)) return false;
      if (element.min !== '' && number < Number(element.min)) return false;
      if (element.max !== '' && number > Number(element.max)) return false;
    }
    if (element.pattern) {
      try {
        if (!(new RegExp('^(?:' + element.pattern + ')$')).test(value)) return false;
      } catch (error) {}
    }
    var minimumLength = Number(element.getAttribute('minlength') || 0);
    var maximumLength = Number(element.getAttribute('maxlength') || 0);
    if (minimumLength && value.length < minimumLength) return false;
    if (maximumLength && value.length > maximumLength) return false;
    if ((type === 'tel' || inputMode === 'numeric') && maximumLength && value.length < maximumLength) return false;
    return true;
  }

  function validateField(element) {
    if (window.__moolMicroDisarmed || !matchesTarget(element)) return;
    if (scenario === 'empty-input') {
      if (!fieldValue(element)) showFieldError(element, controlLabel(element) + ' is required before you continue.');
      else clearFieldError(element);
      return;
    }
    if (scenario === 'invalid-input') {
      if (!validField(element)) showFieldError(element, 'Enter a valid ' + controlLabel(element) + ' and try again.');
      else clearFieldError(element);
    }
  }

  if (routeScenario()) return;

  document.addEventListener('blur', function (event) {
    var element = event.target;
    if (!element || !element.matches || !element.matches('input,textarea,[contenteditable="true"]')) return;
    validateField(element);
  }, true);
  document.addEventListener('input', function (event) {
    var element = event.target;
    if (!element || !element.matches || !element.matches('input,textarea,[contenteditable="true"]')) return;
    if (matchesTarget(element) && validField(element)) clearFieldError(element);
  }, true);

  document.addEventListener('click', function (event) {
    if (window.__moolMicroDisarmed) return;
    var element = event.target && event.target.closest && event.target.closest('button,a[href],[role="button"]');
    if (!element || element.closest('[data-mool-resilience="panel"]') || !matchesTarget(element)) return;
    if (bypassed.has(element)) {
      bypassed.delete(element);
      return;
    }
    var label = controlLabel(element) || 'this action';
    if (scenario === 'action-loading') {
      event.preventDefault();
      event.stopImmediatePropagation();
      renderPanel({
        title: compactLabel(label) + ' is in progress',
        copy: 'Please wait while MoolSocial completes this exact action.',
        context: 'Repeated taps are temporarily blocked.',
        busy: true
      });
      setTimeout(function () {
        replayOriginal(element, compactLabel(label) + ' is continuing.');
      }, 900);
      return;
    }
    if (scenario === 'action-offline' || scenario === 'action-error') {
      event.preventDefault();
      event.stopImmediatePropagation();
      showActionInterruption(element, label, scenario);
      return;
    }
    if (scenario === 'permission-denied') {
      event.preventDefault();
      event.stopImmediatePropagation();
      showPermissionDenied(label);
      return;
    }
    if (scenario === 'duplicate') {
      event.preventDefault();
      event.stopImmediatePropagation();
      showDuplicate(element, label);
    }
  }, true);
}());

(function () {
  "use strict";
  var match = location.pathname.match(/\/(\d{2,3})-[^/]+\.html$/);
  if (!match || [4, 5, 6, 7, 8, 113, 124, 125, 126, 127, 129, 131].indexOf(Number(match[1])) === -1) return;
  if (document.querySelector('script[data-youtube-connect-surface]')) return;
  var source = document.currentScript && document.currentScript.src;
  if (!source) return;
  var script = document.createElement("script");
  script.src = new URL("youtube-connect-surface-runtime.js?v=20260718d", source).href;
  script.dataset.youtubeConnectSurface = "true";
  document.head.appendChild(script);
}());
