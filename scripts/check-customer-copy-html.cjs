const { chromium } = require('../apps/admin/node_modules/playwright');

const baseUrl = process.env.MOOLSOCIAL_SCREENBOOK_URL || 'http://127.0.0.1:8765';
const forbidden = /\b(?:production|prototype|founder review|review build|sample|example|demo|mock|placeholder|working note|internal plan|implementation|workflow|state machine|endpoint|payload|backend|provider callback|next screen|screen 0[1-4]|same verify screen|instead of (?:email|mobile)|this screen is used for|for (?:review|testing))\b/i;

const cases = [
  {
    name: 'Screen 01 customer states',
    path: '/screens/01-app-splash-first-open.html?founderReview=1',
    selector: '.production-phone',
  },
  {
    name: 'Screen 02 consent',
    path: '/screens/02-first-setup-language-location.html?founderReview=1',
    selector: '.final-phone',
  },
  ...[
    'services-off',
    'settings-return',
    'permission-not-allowed',
    'preparing',
    'resolved-current',
    'unavailable',
  ].map((state) => ({
    name: `Screen 02 ${state}`,
    path:
      '/screens/02-first-setup-language-location.html?founderReview=1' +
      `&reviewState=${state}` +
      '&currentArea=Khema-Ka-Kuwa%2C%20Jodhpur%2C%20Rajasthan',
    selector: '.final-phone',
  })),
  {
    name: 'Screen 03 sign-in and mobile OTP',
    path:
      '/screens/03-login-account-handoff.html?founderReview=1' +
      '&area=Khema-Ka-Kuwa%2C%20Jodhpur%2C%20Rajasthan',
    selector: '.phone',
  },
];

function normalize(value) {
  return value.replace(/\s+/g, ' ').trim();
}

async function customerCopy(page, selector) {
  return page.locator(selector).evaluateAll((roots) =>
    roots.map((root) => {
      const attributes = [];
      for (const node of [root, ...root.querySelectorAll('*')]) {
        for (const name of ['aria-label', 'title', 'placeholder', 'alt']) {
          const value = node.getAttribute?.(name);
          if (value) attributes.push(value);
        }
      }
      return `${root.textContent || ''} ${attributes.join(' ')}`;
    }),
  );
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 430, height: 932 } });
  const failures = [];

  try {
    for (const testCase of cases) {
      await page.goto(`${baseUrl}${testCase.path}`, {
        waitUntil: 'networkidle',
      });
      const copies = await customerCopy(page, testCase.selector);
      if (copies.length === 0) {
        failures.push(`${testCase.name}: no customer viewport found`);
        continue;
      }
      for (const copy of copies) {
        const normalized = normalize(copy);
        const match = normalized.match(forbidden);
        if (match) {
          failures.push(
            `${testCase.name}: forbidden wording "${match[0]}" in ${normalized}`,
          );
        }
      }
    }
  } finally {
    await browser.close();
  }

  if (failures.length) {
    console.error(failures.join('\n'));
    process.exitCode = 1;
    return;
  }
  console.log(`Customer-copy HTML gate passed for ${cases.length} states.`);
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
