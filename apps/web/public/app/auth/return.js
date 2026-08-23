(() => {
  'use strict';

  const provider = document.body.dataset.provider;
  const allowedProviders = new Set(['x', 'instagram']);
  const status = document.querySelector('[data-return-status]');
  const openApp = document.querySelector('[data-open-app]');
  const query = window.location.search;

  const failClosed = () => {
    status.textContent = 'This sign-in return is invalid or incomplete. Start again in MoolSocial.';
    openApp.hidden = true;
  };

  if (
    !allowedProviders.has(provider) ||
    window.location.hash !== '' ||
    query.length < 2 ||
    query.length > 4096
  ) {
    failClosed();
    return;
  }

  const parameters = new URLSearchParams(query);
  const allowedNames = new Set([
    'state',
    'code',
    'error',
    'error_reason',
    'error_description',
  ]);
  for (const name of parameters.keys()) {
    if (!allowedNames.has(name) || parameters.getAll(name).length !== 1) {
      failClosed();
      return;
    }
  }
  const state = parameters.get('state');
  const hasCode = parameters.has('code');
  const hasError = parameters.has('error');
  if (!state || state.length !== 43 || hasCode === hasError) {
    failClosed();
    return;
  }

  const appReturn = `moolsocial://auth/${provider}${query}`;
  openApp.href = appReturn;
  openApp.hidden = false;
  status.textContent = 'Returning securely to MoolSocial…';
  window.location.replace(appReturn);
})();
